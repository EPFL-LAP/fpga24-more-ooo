#include "ElasticPass/CircuitGenerator.h"
#include "ElasticPass/Utils.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"

#include <math.h>

//const int N =1;//18;   // the number of tags, hardcoding it for now and need to change it for every example
						// it is needed to define the number of succs and preds of the aligner_branch and aligner_mux 
void delete_File(const std::string& filename) {
    remove(filename.c_str());
}

int CircuitGenerator::get_cmerges_num_from_input(const std::string& tag_info_path) {
	std::string filename = tag_info_path;
    std::ifstream file(filename, std::ifstream::in);

    if (!file) {
        cerr << "Error opening " << filename << " use default loop master value which is phi_0..." << endl;
        return 0;
    }

    string line;
    assert(getline (file, line));  // tagging flag
    assert(getline (file, line));  // number of tags
    assert(getline (file, line));  // number of cmerges

    bool flag_1 = false;
    bool flag_2 = false;
    for(int uu = 0; uu < enode_dag->size(); uu++) {
        if(enode_dag->at(uu)->is_if_else_cmerge)
            flag_1 = true;
        if(enode_dag->at(uu)->is_data_loop_cmerge) {
            flag_2 = true;
        }
    }
    if(!(flag_1 && flag_2))
    	return 2; 

    int number_of_cmerges = std::stoi(line);
    return number_of_cmerges -1;
}

void get_tag_info_file_path(std::string& tag_info_path) {
	std::string filename = PATH_TO_TAG_INFO_PATH;
	std::ifstream file(filename, std::ifstream::in);

	if (!file) {
	    cerr << "Error opening " << filename << " use default file in the following location: /home/dynamatic/Dynamatic/etc/dynamatic/tagging_info.txt" << endl;
	    //tag_info_path = "/home/dynamatic/Dynamatic/etc/dynamatic/tagging_info.txt";
	}

	getline (file, tag_info_path);
}

bool is_tag_from_input(const std::string& tag_info_path) {
	std::string filename = tag_info_path;
	std::ifstream file(filename, std::ifstream::in);

	if (!file) {
	    cerr << "Error opening " << filename << " use default option which is the nontagged version..." << endl;
	    return false;
	}

	string is_tag;
	getline (file, is_tag);

	if(is_tag == "true")
		return true;
	else {
		assert(is_tag == "false");
		return false;
	}

}


int number_of_tags_from_input(const std::string& tag_info_path) {
	std::string filename = tag_info_path;
	std::ifstream file(filename, std::ifstream::in);

	if (!file) {
	    cerr << "Error opening " << filename << " use default tag value which is 1..." << endl;
	    return 1;
	}

	string line;
	assert(getline (file, line));
	assert(getline (file, line));

	int number_of_tags = std::stoi(line);  

	assert(number_of_tags > 0);

	return number_of_tags;
}

void CircuitGenerator::connect_Aligner_Branch_Mux(networkType network_flag, ENode* aligner_branch, ENode* aligner_mux, int N) {
	std::vector<ENode*>* aligner_mux_preds;
	std::vector<ENode*>* aligner_branch_succs;

	switch(network_flag) {
		case data:
			aligner_mux_preds = aligner_mux->CntrlPreds;
			aligner_branch_succs = aligner_branch->CntrlSuccs;
		break;
		case constCntrl:
			aligner_mux_preds = aligner_mux->JustCntrlPreds;
			aligner_branch_succs = aligner_branch->JustCntrlSuccs;
		break;
		case memDeps:
			aligner_mux_preds = aligner_mux->CntrlOrderPreds;
			aligner_branch_succs = aligner_branch->CntrlOrderSuccs;
	}

	for(int i = 0; i < N; i++) {
		aligner_branch_succs->push_back(aligner_mux);
		aligner_mux_preds->push_back(aligner_branch);
	}
}

// AYA: 30/09/2023: building the ALIGNER circuitry
// THis function should be called after addFork because it takes care of adding the forks it needs internally
void CircuitGenerator::build_Aligner(const std::string& tag_info_path, ENode* reference_input, std::vector<ENode*>* other_inputs, ENode* un_tagger, ENode* tagger) {
	// It is important to note that both reference_input and other_inputs are currently directly predecessors of the UN_TAGGER
		// because so far we do not have an ALIGNER component
	// The goal of this function to to add some elastic components between the given inputs and the UN_TAGGER to do the ALIGNER's job

	// sanity check: the un_tagger is at all successors of all of the given inputs 
	/*assert(reference_input->CntrlSuccs->at(0)->type == Un_Tagger);  // if it is a CMerge, its second output will be the control output and is connected to sink
	for(int j = 0; j < reference_input->JustCntrlSuccs->size(); j++)
		assert(reference_input->JustCntrlSuccs->at(j)->type == Un_Tagger);
	for(int k = 0; k < reference_input->CntrlOrderSuccs->size(); k++) 
		assert(reference_input->CntrlOrderSuccs->at(k)->type == Un_Tagger);
	for(int u = 0; u < other_inputs->size(); u++) {
		for(int i = 0; i < other_inputs->at(u)->CntrlSuccs->size(); i++)
			assert(other_inputs->at(u)->CntrlSuccs->at(i)->type == Un_Tagger);
		for(int j = 0; j < other_inputs->at(u)->JustCntrlSuccs->size(); j++)
			assert(other_inputs->at(u)->JustCntrlSuccs->at(j)->type == Un_Tagger);
		for(int k = 0; k < other_inputs->at(u)->CntrlOrderSuccs->size(); k++) 
			assert(other_inputs->at(u)->CntrlOrderSuccs->at(k)->type == Un_Tagger);
	}*/

	// AYa: 09/12/2023:
	int number_of_tags = number_of_tags_from_input(tag_info_path);

	/////////////////////////

	// 1st) The connection between the reference_input and the UN_TAGGER should remain there, so we will do it through a Fork and add more succs to this Fork
	ENode* reference_fork = new ENode(Fork_, "fork", un_tagger->BB); //reference_input->BB); 06/10/2023: replaced the BB with that of the UNTAGGER
	reference_fork->id = fork_id++;
	enode_dag->push_back(reference_fork);

	reference_fork->CntrlPreds->push_back(reference_input);

	//assert(reference_input->CntrlSuccs->size() == 1);
	reference_fork->CntrlSuccs->push_back(reference_input->CntrlSuccs->at(0));

	reference_fork->is_tagged = true;
	reference_fork->tagging_count++;

	// search for the reference input in the pred of its succ (which is the UN_TAGGER)
	auto pos = std::find(reference_input->CntrlSuccs->at(0)->CntrlPreds->begin(), reference_input->CntrlSuccs->at(0)->CntrlPreds->end(), reference_input);
	assert(pos != reference_input->CntrlSuccs->at(0)->CntrlPreds->end());
	int idx = pos - reference_input->CntrlSuccs->at(0)->CntrlPreds->begin();
	reference_input->CntrlSuccs->at(0)->CntrlPreds->at(idx) = reference_fork;

	reference_input->CntrlSuccs->at(0) = reference_fork;

	// 2nd) for every node in other_inputs, we need to add an Aligner_Branch that takes its condition from the tag of its input
			// feeding an Aligner_Mux that takes its condition from the tag of the reference_fork
	for(int i = 0; i < other_inputs->size(); i++) {
		ENode* aligner_branch = new ENode(Aligner_Branch, "aligner_branch", un_tagger->BB); //other_inputs->at(i)->BB); 06/10/2023: replaced the BB with that of the UNTAGGER
		aligner_branch->id = aligner_branch_id++;
		enode_dag->push_back(aligner_branch);

		//aligner_branch->is_tagged = true;
		// AYA: 26/12/2023
		aligner_branch->tagger_id = tagger->id;

		ENode* aligner_mux = new ENode(Aligner_Mux, "aligner_mux", un_tagger->BB); //other_inputs->at(i)->BB); 06/10/2023: replaced the BB with that of the UNTAGGER
		aligner_mux->id = aligner_mux_id++;
		enode_dag->push_back(aligner_mux);

		//aligner_mux->is_tagged = true;
		// AYA: 26/12/2023
		aligner_mux->tagger_id = tagger->id;

		// connect the conditions of the aligner_branch and the aligner_mux following the convention of the usual Mux and Branch
			// the Branch condition comes after its data if the data is in the CntrlSuccs, so we do it in the bottom after connecting the data inputs
			// the Mux condition comes before any other predecessor
		aligner_mux->CntrlPreds->push_back(reference_fork); // in the vhdl_writer, I will make this connection TAG ONLY!!!
		reference_fork->CntrlSuccs->push_back(aligner_mux);

		ENode* aligner_branch_fork = new ENode(Fork_, "fork", aligner_branch->BB);
		aligner_branch_fork->id = fork_id++;
		enode_dag->push_back(aligner_branch_fork);

		aligner_branch_fork->is_tagged = true;
		aligner_branch_fork->tagging_count++;
		aligner_branch_fork->tagger_id = tagger->id;

		// the Branch should be the succ of other_inputs->at(i) and the Mux should be the succ of the Branch and the UN_TAGGER should be the succ of the Mux
		if(other_inputs->at(i)->CntrlSuccs->size() > 0) {
			//assert(other_inputs->at(i)->CntrlSuccs->size() == 1);

			// 1st: connect the aligner_branch and aligner_mux
			connect_Aligner_Branch_Mux(data, aligner_branch, aligner_mux, number_of_tags); 

			// 2nd: replace the pred of the succ of other_inputs->at(i) with the aligner_mux
					// 1st I need to search for the succ of type Un_Tagger because it is the one that we should play around
			auto pos_un_tagger = std::find(other_inputs->at(i)->CntrlSuccs->begin(), other_inputs->at(i)->CntrlSuccs->end(), un_tagger);
			assert(pos_un_tagger != other_inputs->at(i)->CntrlSuccs->end());
			int idx_un_tagger = pos_un_tagger - other_inputs->at(i)->CntrlSuccs->begin();

			auto pos_in_pred_of_succ = std::find(other_inputs->at(i)->CntrlSuccs->at(idx_un_tagger)->CntrlPreds->begin(), other_inputs->at(i)->CntrlSuccs->at(idx_un_tagger)->CntrlPreds->end(), other_inputs->at(i));
			assert(pos_in_pred_of_succ != other_inputs->at(i)->CntrlSuccs->at(idx_un_tagger)->CntrlPreds->end());
			int idx_in_pred_of_succ = pos_in_pred_of_succ - other_inputs->at(i)->CntrlSuccs->at(idx_un_tagger)->CntrlPreds->begin();
			other_inputs->at(i)->CntrlSuccs->at(idx_un_tagger)->CntrlPreds->at(idx_in_pred_of_succ) = aligner_mux;
			aligner_mux->CntrlSuccs->push_back(other_inputs->at(i)->CntrlSuccs->at(idx_un_tagger));

			// 3rd: replace the succ of other_inputs->at(i) with the aligner_branch 
			other_inputs->at(i)->CntrlSuccs->at(idx_un_tagger) = aligner_branch_fork;
			aligner_branch_fork->CntrlPreds->push_back(other_inputs->at(i));

			// 4th: connect the aligner_branch to the succs of the aligner_branch_fork
			aligner_branch_fork->CntrlSuccs->push_back(aligner_branch);
			aligner_branch->CntrlPreds->push_back(aligner_branch_fork);

		} else {
			if(other_inputs->at(i)->JustCntrlSuccs->size() > 0) {
				//assert(other_inputs->at(i)->JustCntrlSuccs->size() == 1);

				// 1st: connect the aligner_branch and aligner_mux
				connect_Aligner_Branch_Mux(constCntrl, aligner_branch, aligner_mux, number_of_tags); 

				// 2nd: replace the pred of the succ of other_inputs->at(i) with the aligner_mux
					// 1st I need to search for the succ of type Un_Tagger because it is the one that we should play around
				auto pos_un_tagger = std::find(other_inputs->at(i)->JustCntrlSuccs->begin(), other_inputs->at(i)->JustCntrlSuccs->end(), un_tagger);
				assert(pos_un_tagger != other_inputs->at(i)->JustCntrlSuccs->end());
				int idx_un_tagger = pos_un_tagger - other_inputs->at(i)->JustCntrlSuccs->begin();

				auto pos_in_pred_of_succ = std::find(other_inputs->at(i)->JustCntrlSuccs->at(idx_un_tagger)->JustCntrlPreds->begin(), other_inputs->at(i)->JustCntrlSuccs->at(idx_un_tagger)->JustCntrlPreds->end(), other_inputs->at(i));
				assert(pos_in_pred_of_succ != other_inputs->at(i)->JustCntrlSuccs->at(idx_un_tagger)->JustCntrlPreds->end());
				int idx_in_pred_of_succ = pos_in_pred_of_succ - other_inputs->at(i)->JustCntrlSuccs->at(idx_un_tagger)->JustCntrlPreds->begin();
				other_inputs->at(i)->JustCntrlSuccs->at(idx_un_tagger)->JustCntrlPreds->at(idx_in_pred_of_succ) = aligner_mux;
				aligner_mux->JustCntrlSuccs->push_back(other_inputs->at(i)->JustCntrlSuccs->at(idx_un_tagger));

				// 3rd: replace the succ of other_inputs->at(i) with the aligner_branch 
				other_inputs->at(i)->JustCntrlSuccs->at(idx_un_tagger) = aligner_branch;
				aligner_branch->JustCntrlPreds->push_back(other_inputs->at(i));

				// 4th: connect the aligner_branch to the succs of the aligner_branch_fork
				aligner_branch_fork->JustCntrlSuccs->push_back(aligner_branch);
				aligner_branch->JustCntrlPreds->push_back(aligner_branch_fork);

			} else {
				//assert(other_inputs->at(i)->CntrlOrderSuccs->size() == 1);

				// 2nd: connect the aligner_branch and aligner_mux
				connect_Aligner_Branch_Mux(memDeps, aligner_branch, aligner_mux, number_of_tags); 

				// 2nd: replace the pred of the succ of other_inputs->at(i) with the aligner_mux
					// 1st I need to search for the succ of type Un_Tagger because it is the one that we should play around
				auto pos_un_tagger = std::find(other_inputs->at(i)->CntrlSuccs->begin(), other_inputs->at(i)->CntrlSuccs->end(), un_tagger);
				assert(pos_un_tagger != other_inputs->at(i)->CntrlSuccs->end());
				int idx_un_tagger = pos_un_tagger - other_inputs->at(i)->CntrlSuccs->begin();

				auto pos_in_pred_of_succ = std::find(other_inputs->at(i)->CntrlOrderSuccs->at(idx_un_tagger)->CntrlOrderPreds->begin(), other_inputs->at(i)->CntrlOrderSuccs->at(idx_un_tagger)->CntrlOrderPreds->end(), other_inputs->at(i));
				assert(pos_in_pred_of_succ != other_inputs->at(i)->CntrlOrderSuccs->at(idx_un_tagger)->CntrlOrderPreds->end());
				int idx_in_pred_of_succ = pos_in_pred_of_succ - other_inputs->at(i)->CntrlOrderSuccs->at(idx_un_tagger)->CntrlOrderPreds->begin();
				other_inputs->at(i)->CntrlOrderSuccs->at(idx_un_tagger)->CntrlOrderPreds->at(idx_in_pred_of_succ) = aligner_mux;
				aligner_mux->CntrlOrderSuccs->push_back(other_inputs->at(i)->CntrlOrderSuccs->at(idx_un_tagger));

				// 3rd: replace the succ of other_inputs->at(i) with the aligner_branch 
				other_inputs->at(i)->CntrlOrderSuccs->at(idx_un_tagger) = aligner_branch;
				aligner_branch->CntrlOrderPreds->push_back(other_inputs->at(i));

				// 4th: connect the aligner_branch to the succs of the aligner_branch_fork
				aligner_branch_fork->CntrlOrderSuccs->push_back(aligner_branch);
				aligner_branch->CntrlOrderPreds->push_back(aligner_branch_fork);

			}

		}

		aligner_branch->CntrlPreds->push_back(aligner_branch_fork);  // in the vhdl_writer, I will make this connection TAG ONLY!!!
		aligner_branch_fork->CntrlSuccs->push_back(aligner_branch);
	}

}

// AYA: 28/09/2023
// This function should be called after inserting the TAGGER, UNTAGGER (and potentially the ALIGNER/ROB) 
	// to make sure to crrectly pass to the TAGGER/UNTAGGER (and potentially the ALIGNER/ROB) the edges to be ALIGNED
		// because the other functions only manage clustering not identifying DIRTY edges, etc..
	// Call this function in the end even after calling the insertTagger_UNTAGGER and addForks

// IMP TO NOTE: in clustering the loop clusters, for now I assume that only one of the Branches of the loop carry values outside the loop
void CircuitGenerator::addMissingAlignerInputs(const std::string& tag_info_path) {
	int number_of_cmerges = get_cmerges_num_from_input(tag_info_path);

	// 2nd: FOR NOW I just TAG inputs of the direct successor of the is_if_else_cmerge and then untag it immediately
		// Then, I will manually position the ALIGNER between the TAGGER and UNTAGGER of this edge!!
	for(auto& enode : *enode_dag) {
		if(enode->is_if_else_cmerge || enode->is_data_loop_cmerge) {
			ENode* dirty_node = nullptr;
			ENode* cluster_exit = nullptr;
			ENode* reference_input = nullptr;

			// 1st: search for the TAGGER and UNTAGGER nodes for the master enode at hand because in general there could be many taggers/untaggers
			ENode* tagger = nullptr;
			ENode* un_tagger = nullptr;
			for(auto& e:*enode_dag) {
				/*if(e->type == Tagger) {
					if(BBMap->at(e->BB)->loop->contains(enode->BB))
						tagger = e;
				}
				if(e->type == Un_Tagger){
					if(BBMap->at(e->BB)->loop->contains(enode->BB))
						un_tagger = e;
				}*/
				// AYA: 26/12/2023: replaced the above code with directly accessing the stored tagger/untagger to avoid mistakes in the presence of multiple taggers/untaggers in the circuit
				if((enode->is_data_loop_cmerge && number_of_cmerges == 2) || (enode->is_if_else_cmerge && number_of_cmerges == 1))
					assert(enode->tagger != nullptr && enode->un_tagger != nullptr);
				tagger = enode->tagger;
			    un_tagger = enode->un_tagger;
			}
			if((enode->is_data_loop_cmerge && number_of_cmerges == 2)|| (enode->is_if_else_cmerge && number_of_cmerges == 1))
				assert(tagger!=nullptr && un_tagger!=nullptr);

			if(enode->is_if_else_cmerge) {
				if(number_of_cmerges == 1) { // consider the insertion of if-then-else ALIGNER only if this is the only cmerge
					cluster_exit = enode;

					reference_input = enode;

				}   
				
				// old way of doing things when I was only supporting the if-then-else case!!
				/*assert(master_cmerge->CntrlSuccs->size() == 2);  // this means 1 data output and 1 control output (which is the extra output of the Merge)

				// since now the if_else_cmerge master node feeds its outputs through the UN_TAGGER, we need to identify which of the succs of the UN_TAGGER correspond to the succs of the if_else_cmerge master node
						// this we can know from the index of the if_else_cmerge master node in the CntrlPreds of the UN_TAGGER because its
								// succ should be at the same index in the CntrlSuccs of the UN_TAGGER should be the same 
				auto pos_in_untagger_preds = std::find(master_cmerge->CntrlSuccs->at(0)->CntrlPreds->begin(), master_cmerge->CntrlSuccs->at(0)->CntrlPreds->end(), master_cmerge);
				assert(pos_in_untagger_preds != master_cmerge->CntrlSuccs->at(0)->CntrlPreds->end());
				int idx_in_untagger_preds = pos_in_untagger_preds - master_cmerge->CntrlSuccs->at(0)->CntrlPreds->begin();

				// we are interested in the succ of the untagger at idx_in_untagger_preds + 1 because the very 1st succ of the untagger is preserved for the fifo of free tags
				dirty_node = master_cmerge->CntrlSuccs->at(0)->CntrlSuccs->at(idx_in_untagger_preds + 1);*/

			} else if(enode->is_data_loop_cmerge) {
				if(number_of_cmerges == 2) {
				// search for a Branch that is at the loop exit of the loop that contains the cmerge master at its header and has one succs outside the loop
					// TODO: Note that for now I assume that there is only one of those!!
				for(int i = 0; i < enode_dag->size(); i++) {
					if(enode_dag->at(i)->BB == nullptr || enode_dag->at(i)->type == Tagger || enode_dag->at(i)->type == Un_Tagger || enode_dag->at(i)->type == Free_Tags_Fifo)
						continue;
					if(BBMap->at(enode_dag->at(i)->BB)->loop == BBMap->at(enode->BB)->loop && 
							(BBMap->at(enode_dag->at(i)->BB)->is_loop_exiting || BBMap->at(enode_dag->at(i)->BB)->is_loop_latch)) {

						if(enode_dag->at(i)->type == Branch_n) {
							if(enode_dag->at(i)->CntrlSuccs->at(0)->type == Un_Tagger || 
								enode_dag->at(i)->CntrlSuccs->at(1)->type == Un_Tagger) {
								cluster_exit = enode_dag->at(i);
								break;
							}
						}

						/*if(enode_dag->at(i)->type == Branch_n) {
							if(enode_dag->at(i)->CntrlSuccs->at(0)->BB != nullptr) {
								if(BBMap->at(enode_dag->at(i)->CntrlSuccs->at(0)->BB)->loop != BBMap->at(enode->BB)->loop) {
									cluster_exit = enode_dag->at(i);
									break;
								}
							}

							if(enode_dag->at(i)->CntrlSuccs->at(1)->BB != nullptr) {
								if(BBMap->at(enode_dag->at(i)->CntrlSuccs->at(1)->BB)->loop != BBMap->at(enode->BB)->loop) {
									cluster_exit = enode_dag->at(i);
									break;
								}
							}
						}*/
					} else {  // AYA: 5/1/24
						if(enode_dag->at(i)->is_if_else_cmerge) {

							if(enode_dag->at(i)->cmerge_data_succs->at(0)->type == Un_Tagger) {
								assert(6!=6);
								cluster_exit = enode_dag->at(i);
								break;
							}
						}
					}
				}
				reference_input = cluster_exit;
				}

			}

			// AYA: 5/1/2024: added the following condition
			if((enode->is_data_loop_cmerge && number_of_cmerges == 2) || (enode->is_if_else_cmerge && number_of_cmerges == 1)) {
				assert(cluster_exit != nullptr);
			
				auto pos_in_untagger_preds = std::find(un_tagger->CntrlPreds->begin(), un_tagger->CntrlPreds->end(), cluster_exit);
				assert(pos_in_untagger_preds != un_tagger->CntrlPreds->end());
				int idx_in_untagger_preds = pos_in_untagger_preds - un_tagger->CntrlPreds->begin();

				// we are interested in the succ of the untagger at idx_in_untagger_preds + 1 because the very 1st succ of the untagger is preserved for the fifo of free tags
				dirty_node = un_tagger->CntrlSuccs->at(idx_in_untagger_preds + 1);

				dirty_node->is_dirty_node = true;

				// TEMPRARILY MAKE THE DIRTY_NODE TAGGED.. it is temporary because I will eventualy insert an UNTAGGER that will undo the TAGGER's effect
				//dirty_node->is_tagged = true;

				// insert the tagger between enode->CntrlSuccs->at(0) and the predecessor that is different from the enode (i.e., master) if any
				// FOR NOW I am only supporting components (i.e., real circuit units not steering units) that have two preds where one of them is the master enode
				assert(dirty_node->CntrlPreds->size() == 2);
				if(dirty_node->CntrlPreds->at(0) == un_tagger) { // through the if_else_cmerge node
					// then insert the .at(1) pred of the dirty node in the pred of the tagger
					tagger->CntrlPreds->push_back(dirty_node->CntrlPreds->at(1));

					// search for the dirty node in the succs of its .at(1) pred to replace it with the tagger
					auto pos = std::find(dirty_node->CntrlPreds->at(1)->CntrlSuccs->begin(), dirty_node->CntrlPreds->at(1)->CntrlSuccs->end(), dirty_node);
					assert(pos != dirty_node->CntrlPreds->at(1)->CntrlSuccs->end());
					int idx = pos - dirty_node->CntrlPreds->at(1)->CntrlSuccs->begin();
					dirty_node->CntrlPreds->at(1)->CntrlSuccs->at(idx) = tagger;   // replace the dirty node with the TAGGER in the succs of its preds

					tagger->CntrlSuccs->push_back(un_tagger);
					un_tagger->CntrlPreds->push_back(tagger);
					un_tagger->CntrlSuccs->push_back(dirty_node);

					dirty_node->CntrlPreds->at(1) = un_tagger;  // replace the original (non dirty) predecessor of the dirty_node with the UN_TAGGER

				} else {
					assert(dirty_node->CntrlPreds->at(1) == un_tagger);  // sanity check: the .at(1) pred should be the un_tagger
					// then insert the .at(0) pred of the dirty node in the pred of the tagger
					tagger->CntrlPreds->push_back(dirty_node->CntrlPreds->at(0));

					// search for the dirty node in the succs of its .at(0) pred to replace it with the tagger
					auto pos = std::find(dirty_node->CntrlPreds->at(0)->CntrlSuccs->begin(), dirty_node->CntrlPreds->at(0)->CntrlSuccs->end(), dirty_node);
					assert(pos != dirty_node->CntrlPreds->at(0)->CntrlSuccs->end());
					int idx = pos - dirty_node->CntrlPreds->at(0)->CntrlSuccs->begin();
					dirty_node->CntrlPreds->at(0)->CntrlSuccs->at(idx) = tagger;   // replace the dirty node with the TAGGER in the succs of its preds

					tagger->CntrlSuccs->push_back(un_tagger);
					un_tagger->CntrlPreds->push_back(tagger);
					un_tagger->CntrlSuccs->push_back(dirty_node);

					dirty_node->CntrlPreds->at(0) = un_tagger;  // replace the original (non dirty) predecessor of the dirty_node with the UN_TAGGER

				}

				// sanity check: Now the two preds of the dirty_node should be the un_tagger
				assert(dirty_node->CntrlPreds->at(0) == un_tagger);
				assert(dirty_node->CntrlPreds->at(1) == un_tagger);

				// sanity check: we should find the dirty_node twice in the succs of the un_tagger
				int count = 0;
				for(int i = 0; i < un_tagger->CntrlSuccs->size(); i++) {
					if(un_tagger->CntrlSuccs->at(i) == dirty_node)
						count++;
				}
				assert(count == 2);
				
				// Construct and Insert the ALIGNER
				std::vector<ENode*>* other_inputs = new std::vector<ENode*>;
				// add all other (excluding the reference_input because it will be the reference) predecessors of the un_tagger to other_inputs
				for(int i = 0; i < un_tagger->CntrlPreds->size(); i++) {
					if(un_tagger->CntrlPreds->at(i) == reference_input)
						continue;
					other_inputs->push_back(un_tagger->CntrlPreds->at(i));
				}
				for(int i = 0; i < un_tagger->JustCntrlPreds->size(); i++) {
					if(un_tagger->JustCntrlPreds->at(i) == reference_input)
						continue;
					other_inputs->push_back(un_tagger->JustCntrlPreds->at(i));
				}
				for(int i = 0; i < un_tagger->CntrlOrderPreds->size(); i++) {
					if(un_tagger->CntrlOrderPreds->at(i) == reference_input)
						continue;
					other_inputs->push_back(un_tagger->CntrlOrderPreds->at(i));
				}
				build_Aligner(tag_info_path, reference_input, other_inputs, un_tagger, tagger);
				
			}
			
		}

	}

}

// AYA: 17/09/2023
void CircuitGenerator::tag_cluster_nodes(const std::string& tag_info_path) {
	int number_of_cmerges = get_cmerges_num_from_input(tag_info_path);

	for(auto& enode :*enode_dag) {
        if(enode->is_data_loop_cmerge && number_of_cmerges == 2) {
	        // loop over all enodes in search for any node belonging to the loop cluster that should be tagged
	        for(auto& enode_2:*enode_dag) {
	        	if(enode_2->BB == nullptr || enode_2->type == Tagger || enode_2->type == Un_Tagger || enode_2->type == Free_Tags_Fifo)  // skip tagger nodes because we do not tag them!
	        		continue;
	        	if(/*(enode_2->type == Fork_ || enode_2->type == Fork_c) &&*/ BBMap->at(enode_2->BB)->loop == BBMap->at(enode->BB)->loop ) {
	        		if(!enode_2->is_tagged) {  // ended up not using the nesting concept so adding htis condition
	        			enode_2->is_tagged = true;
	        			enode_2->tagging_count++;
	        		}
	        	}

	        	// 12/10/2023: supporting the case of a fork fed by the loop exit Branch and feeding the un_tagger
	        	else if(enode_2->CntrlSuccs->size() > 0) {   // AYA: 29/1/2023: made it an else if to avoid counting some components twice 
	        		if(enode_2->CntrlSuccs->at(0)->type == Un_Tagger) {
	        			if(!enode_2->is_tagged) {  // this condition should be here regardless of whether you use nesting or not..
	        				enode_2->is_tagged = true;
		        			enode_2->tagging_count++;
	        			}
	        		}
	        	}
	        }
		}

		if(number_of_cmerges == 1)
		if(enode->is_if_else_cmerge) {
			std::vector<ENode*> if_else_branches;
			assert(enode->old_cond_of_if_else_merge != nullptr);

			for(auto& enode_3 : *enode_dag) {
				// push all Branches that have the same condition as the if_else_cmerge
				//if((enode_3->type == Branch_n && (enode_3->CntrlPreds->at(1) == enode->old_cond_of_if_else_merge || enode_3->CntrlPreds->at(1)->CntrlPreds->at(0) == enode->old_cond_of_if_else_merge)) ||
				//	(enode_3->type == Branch_c && (enode_3->CntrlPreds->at(0) == enode->old_cond_of_if_else_merge || enode_3->CntrlPreds->at(0)->CntrlPreds->at(0) == enode->old_cond_of_if_else_merge) )) {
				if((enode_3->type == Branch_n || enode_3->type == Branch_c) && enode_3->old_cond_of_if_else_branch != nullptr) {
					if(enode_3->old_cond_of_if_else_branch == enode->old_cond_of_if_else_merge) {
						if_else_branches.push_back(enode_3);
						if(!enode_3->is_tagged) { // ended up not using the nesting concept so adding htis condition
							enode_3->is_tagged = true;
							enode_3->tagging_count++;
						}
					}
				}
					
			}
			assert(if_else_branches.size() > 0);

			 // loop over all enodes in search for any node belonging to the loop cluster that should be tagged
	        for(auto& enode_2:*enode_dag) {
	        	if(enode_2->BB == nullptr || enode_2->type == Tagger || enode_2->type == Un_Tagger || enode_2->type == Free_Tags_Fifo)  // skip tagger nodes because we do not tag them!
	        		continue;
	        	// tag any node in a BB that is post dominated by the BB of the master_cmerge but does not post dominate the 
	        	if(/*enode_2->BB == enode->BB ||*/ enode_2->BB != if_else_branches.at(0)->BB &&
	        			((my_post_dom_tree->properlyDominates(enode->BB, enode_2->BB) && !my_post_dom_tree->properlyDominates(enode_2->BB, if_else_branches.at(0)->BB) 
	        				&& BBMap->at(enode_2->BB)->Idx > BBMap->at(if_else_branches.at(0)->BB)->Idx) 
	        				&& enode_2->BB != enode->BB)
	        		) {
	        		if(!enode_2->is_tagged) { // ended up not using the nesting concept so adding htis condition
        				enode_2->is_tagged = true;
	        			enode_2->tagging_count++;
	        		}
	        		
	        	}

	        	// AYA: 03/10/2023: tag also the succs of the if_else_branches that are in the same BB as the branhc (i.e., most likley forks!!)
	        		// loop over if_else_branches searching for succs of the branches that are in the same BB
	        	/*for(int rr = 0; rr < if_else_branches.size(); rr++) {
	        		if(enode_2->BB == if_else_branches.at(rr)->BB) {
	        			if(if_else_branches.at(rr)->type == Branch_n) {
	        				if(enode_2 == if_else_branches.at(rr)->CntrlSuccs->at(0) || enode_2 == if_else_branches.at(rr)->CntrlSuccs->at(1)) {
	        					assert(enode_2->type == Fork_ || enode_2->type == Fork_c);
		        				enode_2->is_tagged = true;
	        				}
	        			} else {
	        				assert(if_else_branches.at(rr)->type == Branch_c);
	        				if(if_else_branches.at(rr)->JustCntrlSuccs->size() > 0) {
	        					if(enode_2 == if_else_branches.at(rr)->JustCntrlSuccs->at(0) || enode_2 == if_else_branches.at(rr)->JustCntrlSuccs->at(1)) {
		        					assert(enode_2->type == Fork_ || enode_2->type == Fork_c);
			        				enode_2->is_tagged = true;
	        					}
	        				} else {
	        					assert(if_else_branches.at(rr)->CntrlOrderSuccs->size() > 0);
	        					if(enode_2 == if_else_branches.at(rr)->CntrlOrderSuccs->at(0) || enode_2 == if_else_branches.at(rr)->CntrlOrderSuccs->at(1)) {
		        					assert(enode_2->type == Fork_ || enode_2->type == Fork_c);
			        				enode_2->is_tagged = true;
	        					}
	        				}
	        			}

	        		}
	        	}*/

	        }  
	        enode->is_tagged = true;
	        enode->tagging_count++;
		}

    }
}

// AYA: 17/09/2023
void CircuitGenerator::insert_tagger_untagger_wrapper(const std::string& tag_info_path) {
	int number_of_cmerges = get_cmerges_num_from_input(tag_info_path);

	// 19/09/2023: added the following loop to fix the positioning of the Branches that are at loop exits of a loop-nest to be in the correct loop exit BBs of each loop
	for(auto& enode :*enode_dag) {
		if(enode->type == Branch_n) {
			enode->BB = enode->CntrlPreds->at(1)->BB;  // make sure that the BB of the Branch matches that of its condition because in FPL'22 I inserted supps in the same BB as their producer
		}
		else if (enode->type == Branch_c) {
			enode->BB = enode->CntrlPreds->at(0)->BB;  // make sure that the BB of the Branch matches that of its condition because in FPL'22 I inserted supps in the same BB as their producer
		}
	}

    for(auto& enode :*enode_dag) {
    	if(number_of_cmerges ==2) 
        if(enode->is_data_loop_cmerge) {
            insert_tagger_untagger_loop_node(enode);
        } 

        if(number_of_cmerges == 1)
	    	if(enode->is_if_else_cmerge) {
	    		insert_tagger_untagger_if_else_node(enode);
	    	}

    }
}

// AYA: 27/09/2023
void CircuitGenerator::insert_tagger_untagger_if_else_node(ENode* if_else_master_cmerge) {
	std::ofstream dbg_file;
	dbg_file.open("debug_if_else_branches_tagger_insertion.txt");

	// takes the master Mux (that is now of type CMerge) of a particular if-else since the TAGGER/UNTAGGER should be inserted in a specific if-then-else
	
	// insert the TAGGER at all data input edges of any Branch having the same condition as the if_else_master_cmerge
		// but since it is now a CMerge not a Mux, it no longer holds the condition in its preds, so instead, store this condition in an extra ENode field stored inside if_else_cmerges
	std::vector<ENode*> if_else_branches;
	assert(if_else_master_cmerge->old_cond_of_if_else_merge != nullptr);

	for(auto& enode : *enode_dag) {
		// push all Branches that have the same condition as the if_else_cmerge
		if((enode->type == Branch_n && enode->CntrlPreds->at(1) == if_else_master_cmerge->old_cond_of_if_else_merge) ||
			(enode->type == Branch_c && enode->CntrlPreds->at(0) == if_else_master_cmerge->old_cond_of_if_else_merge)) {
			if_else_branches.push_back(enode);
		}
	}
	assert(if_else_branches.size() > 0);

	// insert the TAGGER, UNTAGGER and fifo in the BB of the identified Branches
	ENode* new_tagger = new ENode(Tagger, "tagger", if_else_branches.at(0)->BB);
	new_tagger->id = tagger_id++;
	enode_dag->push_back(new_tagger);

	// 14/10/2023: identifying the loop exit BB: AYA: 25/12/2023: see below: replaced the commented out code
	/*BasicBlock* un_tagger_bb;
	for(int kk = 0; kk < bbnode_dag->size(); kk++) {
		if(bbnode_dag->at(kk)->is_loop_exiting ||
			 bbnode_dag->at(kk)->is_loop_latch)
			un_tagger_bb = bbnode_dag->at(kk)->BB;     
	}*/
	// AYA: 25/12/2023: changed the above code to put the untagger in the BB that is the succ of the if_else_master_cmerge
	BasicBlock* un_tagger_bb;
	assert(if_else_master_cmerge->cmerge_data_succs->size() > 0);
	un_tagger_bb = if_else_master_cmerge->cmerge_data_succs->at(0)->BB;

	ENode* new_un_tagger = new ENode(Un_Tagger, "un_tagger", un_tagger_bb);//if_else_branches.at(0)->BB);
	new_un_tagger->id = un_tagger_id++;
	enode_dag->push_back(new_un_tagger);

	// AYA: 3/1/2024: commented out the following
	ENode* new_free_tags_fifo = new ENode(Free_Tags_Fifo, "free_tags_fifo", un_tagger_bb);// if_else_branches.at(0)->BB);
	new_free_tags_fifo->id = free_tags_fifo_id++;
	enode_dag->push_back(new_free_tags_fifo);

	// AYA: 26/12/2023: store the tagger and the un_tagger inside the loop_master_cmerger
	if_else_master_cmerge->tagger = new_tagger;
	if_else_master_cmerge->un_tagger = new_un_tagger;

	// AYA: 3/1/2024: commented out the following
	// connect the tagger and untagger to the fifo of free tags
	new_un_tagger->CntrlSuccs->push_back(new_free_tags_fifo);
	new_free_tags_fifo->CntrlPreds->push_back(new_un_tagger);

	new_tagger->CntrlPreds->push_back(new_free_tags_fifo);
	new_free_tags_fifo->CntrlSuccs->push_back(new_tagger);

	// AYA: 3/1/2024: replaced the above commented code with the following
	// new_un_tagger->CntrlSuccs->push_back(new_tagger);
	// new_tagger->CntrlPreds->push_back(new_un_tagger);

	// connect the inputs of the TAGGER from the data inputs of the Branches in the if_else_branches vector
	for(int i = 0; i < if_else_branches.size(); i++) {

		if(if_else_branches.at(i)->type == Branch_n) {
			dbg_file << getNodeDotTypeNew(if_else_branches.at(i)) << if_else_branches.at(i)->id << ":\n";
		
			new_tagger->CntrlSuccs->push_back(if_else_branches.at(i));

			new_tagger->CntrlPreds->push_back(if_else_branches.at(i)->CntrlPreds->at(0)); 
			// replace the branch from the succ of its data pred with the TAGGER
			if(if_else_branches.at(i)->CntrlPreds->at(0)->is_data_loop_cmerge) {
				auto pos = std::find(if_else_branches.at(i)->CntrlPreds->at(0)->cmerge_data_succs->begin(), if_else_branches.at(i)->CntrlPreds->at(0)->cmerge_data_succs->end(), if_else_branches.at(i)); 
				if(pos == if_else_branches.at(i)->CntrlPreds->at(0)->cmerge_data_succs->end()) {
					dbg_file << "The Branch is NOT present in the succs of its CMERGE preds called " << getNodeDotTypeNew(if_else_branches.at(i)->CntrlPreds->at(0)) << "\n";
				} else {
					dbg_file << "The Branch is present in the succs of its CMERGE preds called " << getNodeDotTypeNew(if_else_branches.at(i)->CntrlPreds->at(0)) << "\n";
				}

				assert(pos != if_else_branches.at(i)->CntrlPreds->at(0)->cmerge_data_succs->end());
				int idx = pos - if_else_branches.at(i)->CntrlPreds->at(0)->cmerge_data_succs->begin();
				if_else_branches.at(i)->CntrlPreds->at(0)->cmerge_data_succs->at(idx) = new_tagger;
			} else {
				auto pos = std::find(if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->begin(), if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->end(), if_else_branches.at(i)); 
				if(pos == if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->end()) {
					dbg_file << "The Branch is NOT present in the succs of its preds called " << getNodeDotTypeNew(if_else_branches.at(i)->CntrlPreds->at(0)) << "\n";
				} else {
					dbg_file << "The Branch is present in the succs of its preds called " << getNodeDotTypeNew(if_else_branches.at(i)->CntrlPreds->at(0)) << "\n";
				}

				assert(pos != if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->end());
				int idx = pos - if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->begin();
				if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->at(idx) = new_tagger;
			}
	
			if_else_branches.at(i)->CntrlPreds->at(0) = new_tagger;

			// THE REST OF THE CODE IN THIS CONDITION WAS ORIGINALLY COMMENTED OUT
			// do the same to tag the condition of the Branch
			/*new_tagger->CntrlSuccs->push_back(if_else_branches.at(i));
			new_tagger->CntrlPreds->push_back(if_else_branches.at(i)->CntrlPreds->at(1));

			// replace the branch from the succ of its condition pred with the TAGGER
			auto pos_2 = std::find(if_else_branches.at(i)->CntrlPreds->at(1)->CntrlSuccs->begin(), if_else_branches.at(i)->CntrlPreds->at(1)->CntrlSuccs->end(), if_else_branches.at(i)); 
			assert(pos_2 != if_else_branches.at(i)->CntrlPreds->at(1)->CntrlSuccs->end());
			int idx_2 = pos_2 - if_else_branches.at(i)->CntrlPreds->at(1)->CntrlSuccs->begin();

			if_else_branches.at(i)->CntrlPreds->at(1)->CntrlSuccs->at(idx_2) = new_tagger;

			if_else_branches.at(i)->CntrlPreds->at(1) = new_tagger;*/

		} else {
			assert(if_else_branches.at(i)->type == Branch_c);
			if(if_else_branches.at(i)->JustCntrlPreds->size() > 0) {
				new_tagger->JustCntrlSuccs->push_back(if_else_branches.at(i));

				new_tagger->JustCntrlPreds->push_back(if_else_branches.at(i)->JustCntrlPreds->at(0));

				// replace the branch from the succ of its data pred with the TAGGER
				if(if_else_branches.at(i)->JustCntrlPreds->at(0)->is_data_loop_cmerge) {
					auto pos = std::find(if_else_branches.at(i)->JustCntrlPreds->at(0)->cmerge_data_succs->begin(), if_else_branches.at(i)->JustCntrlPreds->at(0)->cmerge_data_succs->end(), if_else_branches.at(i)); 
					assert(pos != if_else_branches.at(i)->JustCntrlPreds->at(0)->cmerge_data_succs->end());
					int idx = pos - if_else_branches.at(i)->JustCntrlPreds->at(0)->cmerge_data_succs->begin();
					if_else_branches.at(i)->JustCntrlPreds->at(0)->cmerge_data_succs->at(idx) = new_tagger;
				} else {
					auto pos = std::find(if_else_branches.at(i)->JustCntrlPreds->at(0)->JustCntrlSuccs->begin(), if_else_branches.at(i)->JustCntrlPreds->at(0)->JustCntrlSuccs->end(), if_else_branches.at(i)); 
					assert(pos != if_else_branches.at(i)->JustCntrlPreds->at(0)->JustCntrlSuccs->end());
					int idx = pos - if_else_branches.at(i)->JustCntrlPreds->at(0)->JustCntrlSuccs->begin();
					if_else_branches.at(i)->JustCntrlPreds->at(0)->JustCntrlSuccs->at(idx) = new_tagger;
				}

				if_else_branches.at(i)->JustCntrlPreds->at(0) = new_tagger;

			} else {
				assert(if_else_branches.at(i)->CntrlOrderPreds->size() > 0);
				new_tagger->CntrlOrderSuccs->push_back(if_else_branches.at(i));

				new_tagger->CntrlOrderPreds->push_back(if_else_branches.at(i)->CntrlOrderPreds->at(0));
				// replace the branch from the succ of its data pred with the 
				if(if_else_branches.at(i)->CntrlOrderPreds->at(0)->is_data_loop_cmerge) {
					auto pos = std::find(if_else_branches.at(i)->CntrlOrderPreds->at(0)->cmerge_data_succs->begin(), if_else_branches.at(i)->CntrlOrderPreds->at(0)->cmerge_data_succs->end(), if_else_branches.at(i)); 
					assert(pos != if_else_branches.at(i)->CntrlOrderPreds->at(0)->cmerge_data_succs->end());
					int idx = pos - if_else_branches.at(i)->CntrlOrderPreds->at(0)->cmerge_data_succs->begin();
					if_else_branches.at(i)->CntrlOrderPreds->at(0)->cmerge_data_succs->at(idx) = new_tagger;
				} else {
					auto pos = std::find(if_else_branches.at(i)->CntrlOrderPreds->at(0)->CntrlOrderSuccs->begin(), if_else_branches.at(i)->CntrlOrderPreds->at(0)->CntrlOrderSuccs->end(), if_else_branches.at(i)); 
					assert(pos != if_else_branches.at(i)->CntrlOrderPreds->at(0)->CntrlOrderSuccs->end());
					int idx = pos - if_else_branches.at(i)->CntrlOrderPreds->at(0)->CntrlOrderSuccs->begin();
					if_else_branches.at(i)->CntrlOrderPreds->at(0)->CntrlOrderSuccs->at(idx) = new_tagger;
				}

				if_else_branches.at(i)->CntrlOrderPreds->at(0) = new_tagger;
			}

			// THE REST OF THE CODE IN THIS CONDITION WAS ORIGINALLY COMMENTED OUT
			// do the same to tag the condition of the Branch which is here in the CntrlPreds->at(0)
			/*new_tagger->CntrlSuccs->push_back(if_else_branches.at(i));
			new_tagger->CntrlPreds->push_back(if_else_branches.at(i)->CntrlPreds->at(0));

			// replace the branch from the succ of its condition pred with the TAGGER
			auto pos = std::find(if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->begin(), if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->end(), if_else_branches.at(i)); 
			assert(pos != if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->end());
			int idx = pos - if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->begin();

			if_else_branches.at(i)->CntrlPreds->at(0)->CntrlSuccs->at(idx) = new_tagger;

			if_else_branches.at(i)->CntrlPreds->at(0) = new_tagger;*/
		}
	}

	// insert the UNTAGGER at the output of the master if_else_master_cmerge
	new_un_tagger->CntrlPreds->push_back(if_else_master_cmerge);
	assert(if_else_master_cmerge->cmerge_data_succs->size() > 0);

	for(int i = 0; i < if_else_master_cmerge->cmerge_data_succs->size(); i++) {
		new_un_tagger->CntrlSuccs->push_back(if_else_master_cmerge->cmerge_data_succs->at(i));

		// replace the master_cmerge with the untagger in the pred of its succ
		auto pos = std::find(if_else_master_cmerge->cmerge_data_succs->at(i)->CntrlPreds->begin(), if_else_master_cmerge->cmerge_data_succs->at(i)->CntrlPreds->end(), if_else_master_cmerge);
		assert(pos != if_else_master_cmerge->cmerge_data_succs->at(i)->CntrlPreds->end());
		int idx = pos - if_else_master_cmerge->cmerge_data_succs->at(i)->CntrlPreds->begin();

		if_else_master_cmerge->cmerge_data_succs->at(i)->CntrlPreds->at(idx) = new_un_tagger;

		if_else_master_cmerge->cmerge_data_succs->at(i) = new_un_tagger;
	} 

	delete_File("debug_if_else_branches_tagger_insertion.txt");

}

// AYA: 24: TODO: the conditions added to take care of the case of an UNTAGGER followed by a Mux should be made more general!!
// AYA: 17/09/2023
void CircuitGenerator::insert_tagger_untagger_loop_node(ENode* loop_master_cmerge) {
    // takes the master Mux (that is now of type CMerge) of a particular loop since the TAGGER should be inserted for a specific loop (remember the loop clustering)
	
	// 06/10/2023: VERY IMP: the BBs of the TAGGER/UNTAGGER and ALIGNER should correspond to the loops that they belong to (ie. the # of tokens inputted to them)
		// the tagger should be at the input of the Mux coming from outside the loop
	BasicBlock* tagger_bb = nullptr;
	bool found_tagger_bb = false;
	assert(loop_master_cmerge->CntrlPreds->size() == 2);
	if(loop_master_cmerge->CntrlPreds->at(0)->BB != nullptr) {
		if(BBMap->at(loop_master_cmerge->CntrlPreds->at(0)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
			tagger_bb = loop_master_cmerge->CntrlPreds->at(0)->BB;
			found_tagger_bb = true;
		}
	} 
	if(!found_tagger_bb) {
		if(loop_master_cmerge->CntrlPreds->at(1)->BB != nullptr) {
			if(BBMap->at(loop_master_cmerge->CntrlPreds->at(1)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
				tagger_bb = loop_master_cmerge->CntrlPreds->at(1)->BB;
				found_tagger_bb = true;
			}
		} 
	}
	assert(tagger_bb != nullptr && found_tagger_bb); 
	ENode* new_tagger = new ENode(Tagger, "tagger", tagger_bb);
	new_tagger->id = tagger_id++;
	enode_dag->push_back(new_tagger);

		// the un_tagger should be at the output of the Branch that goes outside the loop
	// search for a Branch at the loop exit of this loop that has a successor outside of this loop
	BasicBlock* un_tagger_bb = nullptr;
	bool found_un_tagger_bb = false;
	for(auto enode_ : *enode_dag) {
		if(enode_->BB == nullptr)
			continue;

		if( BBMap->at(enode_->BB)->loop == BBMap->at(loop_master_cmerge->BB)->loop &&
				 (BBMap->at(enode_->BB)->is_loop_exiting || BBMap->at(enode_->BB)->is_loop_latch) &&
				 	enode_->type == Branch_n ) {
			assert(enode_->true_branch_succs->size() + enode_->false_branch_succs->size() > 0);

			for(int i = 0; i < enode_->true_branch_succs->size(); i++) {
				if(enode_->true_branch_succs->at(i)->BB != nullptr) {
					if(BBMap->at(enode_->true_branch_succs->at(i)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
						un_tagger_bb = enode_->true_branch_succs->at(i)->BB;
						found_un_tagger_bb = true;
						break;
					}
				} 
			}
			if(!found_tagger_bb) {
				for(int i = 0; i < enode_->false_branch_succs->size(); i++) {
					if(enode_->false_branch_succs->at(i)->BB != nullptr) {
						if(BBMap->at(enode_->false_branch_succs->at(i)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
							un_tagger_bb = enode_->false_branch_succs->at(i)->BB;
							found_un_tagger_bb = true;
							break;
						}
					} 
				}
			}

		}
	}
	assert(un_tagger_bb != nullptr && found_un_tagger_bb); 

	ENode* new_un_tagger = new ENode(Un_Tagger, "un_tagger", un_tagger_bb);
	new_un_tagger->id = un_tagger_id++;
	enode_dag->push_back(new_un_tagger);

	// AYA: 26/12/2023:
	new_un_tagger->tagger_id = new_tagger->id;

	// AYA: 3/1/2024: commented out the following
	// let's make the free fifo tag in the same BB as that of the tagger
	ENode* new_free_tags_fifo = new ENode(Free_Tags_Fifo, "free_tags_fifo", new_un_tagger->BB);
	new_free_tags_fifo->id = free_tags_fifo_id++;
	enode_dag->push_back(new_free_tags_fifo);

	// AYA: 26/12/2023: store the tagger and the un_tagger inside the loop_master_cmerger
	loop_master_cmerge->tagger = new_tagger;
	loop_master_cmerge->un_tagger = new_un_tagger;

	// temporarily: the in0 of the tagger will be fed from a constant, but later, it should be fed from the tagger!!
	/*std::string cst_name = std::to_string(3);
	ENode* tagger_constant = new ENode(Cst_, cst_name.c_str(), new_tagger->BB);
	tagger_constant->cstValue = 3;
	tagger_constant->id = cst_id++;
	enode_dag->push_back(tagger_constant);
	new_tagger->CntrlPreds->push_back(tagger_constant);
	tagger_constant->CntrlSuccs->push_back(new_tagger);
	// temporarily, try testing by trigerring it from a constant
	ENode* source_node = new ENode(Source_, "source", new_tagger->BB);
	source_node->id    = source_id++;
	tagger_constant->JustCntrlPreds->push_back(source_node);
	source_node->JustCntrlSuccs->push_back(tagger_constant);
	enode_dag->push_back(source_node);*/
	////////////////////////////////// replace the above part with the untagger!!

	// AYA: 3/1/2024: commented out the following
	new_un_tagger->CntrlSuccs->push_back(new_free_tags_fifo);
	new_free_tags_fifo->CntrlPreds->push_back(new_un_tagger);
	new_tagger->CntrlPreds->push_back(new_free_tags_fifo);
	new_free_tags_fifo->CntrlSuccs->push_back(new_tagger);

	// AYA: 3/1/2024: replaced the above commented code with the following
	// new_un_tagger->CntrlSuccs->push_back(new_tagger);
	// new_tagger->CntrlPreds->push_back(new_un_tagger);

	/*new_un_tagger->CntrlSuccs->push_back(new_tagger);
	new_tagger->CntrlPreds->push_back(new_un_tagger);*/

	// will connect the untagger's preds and the remaining succs at the end of this function

	for(auto&enode :*enode_dag) {
		if(enode->BB == nullptr)
			continue;
		// blindly tag all nodes belonging to this loop, including the loop_master_cmerge itself
		if(BBMap->at(enode->BB)->loop == BBMap->at(loop_master_cmerge->BB)->loop && enode!=new_tagger) {
			//enode->is_tagged = true;   // moved the tagging option to another function to easily turn it on or off

			// insert the TAGGER at the in0 of all Muxes of that loop
			if((enode->isMux || enode->is_data_loop_cmerge) && enode->BB == loop_master_cmerge->BB) {
				//new_tagger->CntrlSuccs->push_back(enode);

				if(enode->type == Phi_ || enode->type == Phi_n) {
					new_tagger->CntrlSuccs->push_back(enode);

					int in0_pred_idx = -1;
					if(enode->is_data_loop_cmerge) {
						assert(enode == loop_master_cmerge);
						assert(enode->CntrlPreds->size() == 2);
						in0_pred_idx = 0;
					} else {
						assert(enode->CntrlPreds->size() == 3);
						in0_pred_idx = 1;
					}

					new_tagger->CntrlPreds->push_back(enode->CntrlPreds->at(in0_pred_idx));

					// search for the enode in the succ of its pred to replace it with the TAGGER
					if(enode->CntrlPreds->at(in0_pred_idx)->type == Branch_n) {
						// search in the Branch's succs
						auto pos_true = std::find(enode->CntrlPreds->at(in0_pred_idx)->true_branch_succs->begin(), enode->CntrlPreds->at(in0_pred_idx)->true_branch_succs->end(), enode);
						if(pos_true != enode->CntrlPreds->at(in0_pred_idx)->true_branch_succs->end()) {
							int idx = pos_true - enode->CntrlPreds->at(in0_pred_idx)->true_branch_succs->begin();
							enode->CntrlPreds->at(in0_pred_idx)->true_branch_succs->at(idx) = new_tagger;
						} else {
							auto pos_false = std::find(enode->CntrlPreds->at(in0_pred_idx)->false_branch_succs->begin(), enode->CntrlPreds->at(in0_pred_idx)->false_branch_succs->end(), enode);
							assert(pos_false != enode->CntrlPreds->at(in0_pred_idx)->false_branch_succs->end());
							int idx = pos_false - enode->CntrlPreds->at(in0_pred_idx)->false_branch_succs->begin();
							enode->CntrlPreds->at(in0_pred_idx)->false_branch_succs->at(idx) = new_tagger;
						}
						
					} else {
						assert(enode->CntrlPreds->at(in0_pred_idx)->type != Branch_c);

						auto pos = std::find(enode->CntrlPreds->at(in0_pred_idx)->CntrlSuccs->begin(), enode->CntrlPreds->at(in0_pred_idx)->CntrlSuccs->end(), enode);
						assert(pos != enode->CntrlPreds->at(in0_pred_idx)->CntrlSuccs->end());
						int idx = pos - enode->CntrlPreds->at(in0_pred_idx)->CntrlSuccs->begin();
						enode->CntrlPreds->at(in0_pred_idx)->CntrlSuccs->at(idx) = new_tagger;
					}

					enode->CntrlPreds->at(in0_pred_idx) = new_tagger;

				} else {
					assert(enode->type == Phi_c);

					new_tagger->JustCntrlSuccs->push_back(enode);


					if(enode->JustCntrlPreds->size() > 0) {
						assert(enode->CntrlOrderPreds->size() == 0);
						new_tagger->JustCntrlPreds->push_back(enode->JustCntrlPreds->at(0));

						// search for the enode in the succ of its pred to replace it with the TAGGER
						if(enode->JustCntrlPreds->at(0)->type == Branch_c) {
							// search in the Branch's succs
							auto pos_true = std::find(enode->JustCntrlPreds->at(0)->true_branch_succs_Ctrl->begin(), enode->JustCntrlPreds->at(0)->true_branch_succs_Ctrl->end(), enode);
							if(pos_true != enode->JustCntrlPreds->at(0)->true_branch_succs_Ctrl->end()) {
								int idx = pos_true - enode->JustCntrlPreds->at(0)->true_branch_succs_Ctrl->begin();
								enode->JustCntrlPreds->at(0)->true_branch_succs_Ctrl->at(idx) = new_tagger;
							} else {
								auto pos_false = std::find(enode->JustCntrlPreds->at(0)->false_branch_succs_Ctrl->begin(), enode->JustCntrlPreds->at(0)->false_branch_succs_Ctrl->end(), enode);
								assert(pos_false != enode->JustCntrlPreds->at(0)->false_branch_succs_Ctrl->end());
								int idx = pos_false - enode->JustCntrlPreds->at(0)->false_branch_succs_Ctrl->begin();
								enode->JustCntrlPreds->at(0)->false_branch_succs_Ctrl->at(idx) = new_tagger;
							}
							
						} else {
							assert(enode->JustCntrlPreds->at(0)->type != Branch_n);

							auto pos = std::find(enode->JustCntrlPreds->at(0)->JustCntrlSuccs->begin(), enode->JustCntrlPreds->at(0)->JustCntrlSuccs->end(), enode);
							assert(pos != enode->JustCntrlPreds->at(0)->JustCntrlSuccs->end());
							int idx = pos - enode->JustCntrlPreds->at(0)->JustCntrlSuccs->begin();
							enode->JustCntrlPreds->at(0)->JustCntrlSuccs->at(idx) = new_tagger;
						}

						enode->JustCntrlPreds->at(0) = new_tagger;

					} else {
						assert(enode->CntrlOrderPreds->size() > 0);
						new_tagger->CntrlOrderPreds->push_back(enode->CntrlOrderPreds->at(0));

						// search for the enode in the succ of its pred to replace it with the TAGGER
						if(enode->CntrlOrderPreds->at(0)->type == Branch_c) {
							// search in the Branch's succs
							auto pos_true = std::find(enode->CntrlOrderPreds->at(0)->true_branch_succs_Ctrl_lsq->begin(), enode->CntrlOrderPreds->at(0)->true_branch_succs_Ctrl_lsq->end(), enode);
							if(pos_true != enode->CntrlOrderPreds->at(0)->true_branch_succs_Ctrl_lsq->end()) {
								int idx = pos_true - enode->CntrlOrderPreds->at(0)->true_branch_succs_Ctrl_lsq->begin();
								enode->CntrlOrderPreds->at(0)->true_branch_succs_Ctrl_lsq->at(idx) = new_tagger;
							} else {
								auto pos_false = std::find(enode->CntrlOrderPreds->at(0)->false_branch_succs_Ctrl_lsq->begin(), enode->CntrlOrderPreds->at(0)->false_branch_succs_Ctrl_lsq->end(), enode);
								assert(pos_false != enode->CntrlOrderPreds->at(0)->false_branch_succs_Ctrl_lsq->end());
								int idx = pos_false - enode->CntrlOrderPreds->at(0)->false_branch_succs_Ctrl_lsq->begin();
								enode->CntrlOrderPreds->at(0)->false_branch_succs_Ctrl_lsq->at(idx) = new_tagger;
							}
							
						} else {
							assert(enode->CntrlOrderPreds->at(0)->type != Branch_n);

							auto pos = std::find(enode->CntrlOrderPreds->at(0)->CntrlOrderSuccs->begin(), enode->CntrlOrderPreds->at(0)->CntrlOrderSuccs->end(), enode);
							assert(pos != enode->CntrlOrderPreds->at(0)->CntrlOrderSuccs->end());
							int idx = pos - enode->CntrlOrderPreds->at(0)->CntrlOrderSuccs->begin();
							enode->CntrlOrderPreds->at(0)->CntrlOrderSuccs->at(idx) = new_tagger;
						}
						enode->CntrlOrderPreds->at(0) = new_tagger;

					}
					////////////////////
				}
			}
		}
	}

	// insert the untagger
		// search for the Branches at thr loop exit of the loop that are themselves inside the loop but has one of their succs outside of the loop
	for(auto&enode :*enode_dag) {
		if(enode->BB == nullptr)
			continue;
		// blindly tag all nodes belonging to this loop, including the loop_master_cmerge itself
		if(BBMap->at(enode->BB)->loop == BBMap->at(loop_master_cmerge->BB)->loop) {
			// search for Branches at the loop exit 
			if( (enode->type == Branch_n || enode->type == Branch_c) && (BBMap->at(enode->BB)->is_loop_exiting || BBMap->at(enode->BB)->is_loop_latch) 
			) {
				// this Branch must be having a successor outside of the loop to insert the untagger between them
					// I will simply loop over all types of successors of a Branch in search for any succ that is outside of this loop
				bool found_succ_out_loop = false;
				ENode* branch_succ_out_loop = nullptr;
				int branch_supp_idx = -1;

				if(enode->type == Branch_n) {
					for(int i = 0; i < enode->true_branch_succs->size(); i++) {
						if(enode->true_branch_succs->at(i)->BB != nullptr) {
							if(BBMap->at(enode->true_branch_succs->at(i)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
								found_succ_out_loop = true;
								branch_succ_out_loop = enode->true_branch_succs->at(i);
								branch_supp_idx = i;
								break;
							}
						}
					}
					if(found_succ_out_loop) {
						assert(branch_succ_out_loop != nullptr && branch_supp_idx != -1);

						// AYA: 5/1/2024: added a condition to move the untagger below if the found_succ is a Mux or CMerge
						ENode* actual_Enode = nullptr;
						// assert(branch_succ_out_loop->type != Phi_c);
						// if(branch_succ_out_loop->type == Phi_ || branch_succ_out_loop->type == Phi_n) {
						// 	actual_Enode = branch_succ_out_loop;
						// 	if(branch_succ_out_loop->is_if_else_cmerge) {
						// 		assert(branch_succ_out_loop->cmerge_data_succs->size() == 1);
						// 		branch_succ_out_loop = branch_succ_out_loop->cmerge_data_succs->at(0);
						// 	} else {
						// 		assert(branch_succ_out_loop->CntrlSuccs->size() == 1);
						// 		branch_succ_out_loop = branch_succ_out_loop->CntrlSuccs->at(0);
						// 	}
						// }
						if(actual_Enode == nullptr)
							actual_Enode = enode;
						///////////////////////////////

						// insert the untagger here
						new_un_tagger->CntrlPreds->push_back(actual_Enode);
						new_un_tagger->CntrlSuccs->push_back(branch_succ_out_loop);

						// search for the enode in the preds of branch_succ_out_loop to replace it with the untagger
						auto pos = std::find(branch_succ_out_loop->CntrlPreds->begin(), branch_succ_out_loop->CntrlPreds->end(), actual_Enode);
						assert(pos != branch_succ_out_loop->CntrlPreds->end());
						int idx = pos - branch_succ_out_loop->CntrlPreds->begin();

						branch_succ_out_loop->CntrlPreds->at(idx) = new_un_tagger;

						if(actual_Enode->type == Branch_n)
							actual_Enode->true_branch_succs->at(branch_supp_idx) = new_un_tagger;
						else {
							if(actual_Enode->is_if_else_cmerge)
								actual_Enode->cmerge_data_succs->at(0);
							else
								actual_Enode->CntrlSuccs->at(0) = new_un_tagger;
						}

					} else {
						for(int i = 0; i < enode->false_branch_succs->size(); i++) {
							if(enode->false_branch_succs->at(i)->BB != nullptr) {
								if(BBMap->at(enode->false_branch_succs->at(i)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
									found_succ_out_loop = true;
									branch_succ_out_loop = enode->false_branch_succs->at(i);
									branch_supp_idx = i;
									break;
								}
							}
						}

						if(found_succ_out_loop) {
							assert(branch_succ_out_loop != nullptr && branch_supp_idx != -1);
							// insert the untagger here
							new_un_tagger->CntrlPreds->push_back(enode);
							new_un_tagger->CntrlSuccs->push_back(branch_succ_out_loop);

							// search for the enode in the preds of branch_succ_out_loop to replace it with the untagger
							auto pos = std::find(branch_succ_out_loop->CntrlPreds->begin(), branch_succ_out_loop->CntrlPreds->end(), enode);
							assert(pos != branch_succ_out_loop->CntrlPreds->end());
							int idx = pos - branch_succ_out_loop->CntrlPreds->begin();

							branch_succ_out_loop->CntrlPreds->at(idx) = new_un_tagger;

							enode->false_branch_succs->at(branch_supp_idx) = new_un_tagger;
						} 
					}

				} else {
					assert(enode->type == Branch_c);
					if(enode->true_branch_succs_Ctrl->size() + enode->true_branch_succs_Ctrl->size() > 0) {
						for(int i = 0; i < enode->true_branch_succs_Ctrl->size(); i++) {
							if(enode->true_branch_succs_Ctrl->at(i)->BB != nullptr) {
								if(BBMap->at(enode->true_branch_succs_Ctrl->at(i)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
									found_succ_out_loop = true;
									branch_succ_out_loop = enode->true_branch_succs_Ctrl->at(i);
									branch_supp_idx = i;
									break;
								}
							}
						}
						if(found_succ_out_loop) {
							assert(branch_succ_out_loop != nullptr && branch_supp_idx != -1);
							// insert the untagger here
							new_un_tagger->JustCntrlPreds->push_back(enode);
							new_un_tagger->JustCntrlSuccs->push_back(branch_succ_out_loop);

							// search for the enode in the preds of branch_succ_out_loop to replace it with the untagger
							auto pos = std::find(branch_succ_out_loop->JustCntrlPreds->begin(), branch_succ_out_loop->JustCntrlPreds->end(), enode);
							assert(pos != branch_succ_out_loop->JustCntrlPreds->end());
							int idx = pos - branch_succ_out_loop->JustCntrlPreds->begin();

							branch_succ_out_loop->JustCntrlPreds->at(idx) = new_un_tagger;

							enode->true_branch_succs_Ctrl->at(branch_supp_idx) = new_un_tagger;

						} else {
							for(int i = 0; i < enode->false_branch_succs_Ctrl->size(); i++) {
								if(enode->false_branch_succs_Ctrl->at(i)->BB != nullptr) {
									if(BBMap->at(enode->false_branch_succs_Ctrl->at(i)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
										found_succ_out_loop = true;
										branch_succ_out_loop = enode->false_branch_succs_Ctrl->at(i);
										branch_supp_idx = i;
										break;
									}
								}
							}

							if(found_succ_out_loop) {
								assert(branch_succ_out_loop != nullptr && branch_supp_idx != -1);
								// insert the untagger here
								new_un_tagger->JustCntrlPreds->push_back(enode);
								new_un_tagger->JustCntrlSuccs->push_back(branch_succ_out_loop);

								// search for the enode in the preds of branch_succ_out_loop to replace it with the untagger
								auto pos = std::find(branch_succ_out_loop->JustCntrlPreds->begin(), branch_succ_out_loop->JustCntrlPreds->end(), enode);
								assert(pos != branch_succ_out_loop->JustCntrlPreds->end());
								int idx = pos - branch_succ_out_loop->JustCntrlPreds->begin();

								branch_succ_out_loop->JustCntrlPreds->at(idx) = new_un_tagger;

								enode->false_branch_succs_Ctrl->at(branch_supp_idx) = new_un_tagger;
							} 
						}
					} else {				
						for(int i = 0; i < enode->true_branch_succs_Ctrl_lsq->size(); i++) {
							if(enode->true_branch_succs_Ctrl_lsq->at(i)->BB != nullptr) {
								if(BBMap->at(enode->true_branch_succs_Ctrl_lsq->at(i)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
									found_succ_out_loop = true;
									branch_succ_out_loop = enode->true_branch_succs_Ctrl_lsq->at(i);
									branch_supp_idx = i;
									break;
								}
							}
						}
						if(found_succ_out_loop) {
							assert(branch_succ_out_loop != nullptr && branch_supp_idx != -1);
							// insert the untagger here
							new_un_tagger->CntrlOrderPreds->push_back(enode);
							new_un_tagger->CntrlOrderSuccs->push_back(branch_succ_out_loop);

							// search for the enode in the preds of branch_succ_out_loop to replace it with the untagger
							auto pos = std::find(branch_succ_out_loop->CntrlOrderPreds->begin(), branch_succ_out_loop->CntrlOrderPreds->end(), enode);
							assert(pos != branch_succ_out_loop->CntrlOrderPreds->end());
							int idx = pos - branch_succ_out_loop->CntrlOrderPreds->begin();

							branch_succ_out_loop->CntrlOrderPreds->at(idx) = new_un_tagger;

							enode->true_branch_succs_Ctrl_lsq->at(branch_supp_idx) = new_un_tagger;

						} else {
							for(int i = 0; i < enode->false_branch_succs_Ctrl_lsq->size(); i++) {
								if(enode->false_branch_succs_Ctrl_lsq->at(i)->BB != nullptr) {
									if(BBMap->at(enode->false_branch_succs_Ctrl_lsq->at(i)->BB)->loop != BBMap->at(loop_master_cmerge->BB)->loop) {
										found_succ_out_loop = true;
										branch_succ_out_loop = enode->false_branch_succs_Ctrl_lsq->at(i);
										branch_supp_idx = i;
										break;
									}
								}
							}

							if(found_succ_out_loop) {
								assert(branch_succ_out_loop != nullptr && branch_supp_idx != -1);
								// insert the untagger here
								new_un_tagger->CntrlOrderPreds->push_back(enode);
								new_un_tagger->CntrlOrderSuccs->push_back(branch_succ_out_loop);

								// search for the enode in the preds of branch_succ_out_loop to replace it with the untagger
								auto pos = std::find(branch_succ_out_loop->CntrlOrderPreds->begin(), branch_succ_out_loop->CntrlOrderPreds->end(), enode);
								assert(pos != branch_succ_out_loop->CntrlOrderPreds->end());
								int idx = pos - branch_succ_out_loop->CntrlOrderPreds->begin();

								branch_succ_out_loop->CntrlOrderPreds->at(idx) = new_un_tagger;

								enode->false_branch_succs_Ctrl_lsq->at(branch_supp_idx) = new_un_tagger;
							} 
						}

					}

				}
				
			}
		}
	}

}

// AYa: 05/08/2023: the goal of this function is to identify components inside a loop as tagged by setting the tagged flag of the enode to true
void CircuitGenerator::tag_some_components() {
	for(auto& enode : *enode_dag) {
		if(enode->type == MC_ || enode->type == LSQ_ || enode->type == Start_ || enode->type == End_ || enode->type == Sink_ ||
				enode->type == Loop_Phi_n || enode->type == Loop_Phi_c || enode->type == LoopMux_Synch)
			continue;  // those types should not need tagging

		if(enode->is_st_ack_to_end)   
			continue; // skip if it is a Branch or a Phi added between a store operation and End_.. I identify those by an extra field called is_st_ack_to_end

		if(enode->BB == nullptr)
			continue;

		// if the enode is inside any loop 
		if(BBMap->at(enode->BB)->loop != nullptr) {
			enode->is_tagged = true;
		}
	}
	fix_tagged_inputs();
}

// The goal of this function is to fulfill our later convention that any component conencted at pred.at(0) has a correct tag
// it is called inside tag_some_components function 
void CircuitGenerator::fix_tagged_inputs() {
	for(auto& enode : *enode_dag) {
		if(enode->type == MC_ || enode->type == LSQ_ || enode->type == Start_ || enode->type == End_ || enode->type == Sink_ ||
				enode->type == Loop_Phi_n || enode->type == Loop_Phi_c || enode->type == LoopMux_Synch)
			continue;  // those types should not need tagging

		if(enode->type == Branch_n || enode->type == Branch_c)
			continue;

		if(enode->is_st_ack_to_end)   
			continue; // skip if it is a Branch or a Phi added between a store operation and End_.. I identify those by an extra field called is_st_ack_to_end

		// In propagating the tag in the VHDL designs of the components, I always take the 0th input, so I would not want it to be Cst_ because Cst_ has tag ports for consistency, but they do not carry any meaninggul tag
		if(enode->CntrlPreds->size() > 0) {
			if(enode->CntrlPreds->at(0)->type == Cst_ || 
					(enode->CntrlPreds->at(0)->type == Fork_ && enode->CntrlPreds->at(0)->CntrlPreds->at(0)->type == Cst_)) {
				assert(enode->CntrlPreds->size() > 1);

				assert(enode->CntrlPreds->at(1)->type != Cst_ && !(enode->CntrlPreds->at(1)->type == Fork_ && enode->CntrlPreds->at(1)->CntrlPreds->at(0)->type == Cst_) ); 
			
				// swap the 0th pred and the 1st pred
				ENode* temp = enode->CntrlPreds->at(0);
				enode->CntrlPreds->at(0) = enode->CntrlPreds->at(1);
				enode->CntrlPreds->at(1) = temp;

			}
		}

	}
}

void CircuitGenerator::insert_loop_exit_robs() {
	for(auto & enode : *enode_dag) {
		if(enode->type != Branch_n)
			continue; 

		if(BBMap->at(enode->BB)->loop == nullptr)
			continue; // skip if the Branch is not inside any loop

		// check if the Branch is inside a loop, but one of the successors of the Branch are outside of this loop

		ENode* loop_exit_branch = nullptr;
		int succ_idx_out_of_loop = -1;

			// I assume that this function is called after connecting the successors of the Branch in the CntrlSUccs network
		assert(enode->CntrlSuccs->size() == 2);
		assert(enode->CntrlPreds->size() == 2);
		
		if(enode->CntrlSuccs->at(0)->BB != nullptr) {
			// check if this succ is inside the same loop as that of the branch
			if(BBMap->at(enode->CntrlSuccs->at(0)->BB)->loop != BBMap->at(enode->BB)->loop) {
				succ_idx_out_of_loop = 0;
			} else {
				// succ.at(0) is not in the same loop as the Branch
				if(enode->CntrlSuccs->at(1)->BB != nullptr) {
					if(BBMap->at(enode->CntrlSuccs->at(1)->BB)->loop != BBMap->at(enode->BB)->loop) {
						succ_idx_out_of_loop = 1;
					}
				}
			}
		} else {
			assert(enode->CntrlSuccs->at(1)->BB != nullptr);
			if(BBMap->at(enode->CntrlSuccs->at(1)->BB)->loop != BBMap->at(enode->BB)->loop) {
				succ_idx_out_of_loop = 1;
			}
		}

		if(succ_idx_out_of_loop != -1) {
			loop_exit_branch = enode;

			// 1st search for a LoopMux that is at the loop header of the loop that the Branch is inside..
			ENode* loop_mux = nullptr;
			for(auto enode_2 :*enode_dag) {
				if(enode_2->type == Loop_Phi_n && BBMap->at(enode_2->BB)->loop == BBMap->at(loop_exit_branch->BB)->loop) {
					loop_mux = enode_2;
					break;
				}
			}
			assert(loop_mux!=nullptr);

			// should insert an ROB between the loop_exit_branch and its CntrlSucc.at(succ_idx_out_of_loop)
			ENode* rob_node = new ENode(ROB, "rob", loop_exit_branch->BB);  
            rob_node->id = rob_id++;

            // an ROB takes two inputs and produces one output. My convention is that the first input is the target tag and the second input is the real data which is the succ of the branch
    			// the convention of the LoopMux is that the CntrlSuccs.at(0) is the actual data output of the LoopMux and CntrlSuccs.at(1) is the tag output
        	loop_mux->CntrlSuccs->push_back(rob_node);
        	rob_node->CntrlPreds->push_back(loop_mux);

            rob_node->CntrlSuccs->push_back(loop_exit_branch->CntrlSuccs->at(succ_idx_out_of_loop));

            // search for the branch in the preds of its succ to replace it with the rob_node
            auto pos = std::find(loop_exit_branch->CntrlSuccs->at(succ_idx_out_of_loop)->CntrlPreds->begin(), loop_exit_branch->CntrlSuccs->at(succ_idx_out_of_loop)->CntrlPreds->end(), loop_exit_branch);
            assert(pos != loop_exit_branch->CntrlSuccs->at(succ_idx_out_of_loop)->CntrlPreds->end());
            int idx = pos - loop_exit_branch->CntrlSuccs->at(succ_idx_out_of_loop)->CntrlPreds->begin();
            loop_exit_branch->CntrlSuccs->at(succ_idx_out_of_loop)->CntrlPreds->at(idx) = rob_node;

            rob_node->CntrlPreds->push_back(loop_exit_branch);
            loop_exit_branch->CntrlSuccs->at(succ_idx_out_of_loop) = rob_node;

            enode_dag->push_back(rob_node);

		}
	}
	// fix any LoopMux that might have ended up feeding multiple ROBs from its tag_output
	addFork_LoopMux_tagOutput();
}

void CircuitGenerator::addFork_LoopMux_tagOutput() {
	for(auto& enode: *enode_dag) {
		if(enode->type == Loop_Phi_n) {   // In the previous function, I only considered Loop_Phi_n as the one providing the tag_out so no need to check Loop_Phi_c as well
			if(enode->CntrlSuccs->size() > 2) {
				// add a Fork and let it feed all succs starting from succ.at(1)
				ENode* fork = new ENode(Fork_, "fork", enode->BB);
				fork->id = fork_id++;

				for(int i = 1; i < enode->CntrlSuccs->size(); i++) {
					fork->CntrlSuccs->push_back(enode->CntrlSuccs->at(i));

					// find the loopMux in the pred of the succ to replace it with the fork
					auto pos_ = std::find(enode->CntrlSuccs->at(i)->CntrlPreds->begin(), enode->CntrlSuccs->at(i)->CntrlPreds->end(), enode);
					assert(pos_ != enode->CntrlSuccs->at(i)->CntrlPreds->end());
					int idx_ = pos_ - enode->CntrlSuccs->at(i)->CntrlPreds->begin();
					enode->CntrlSuccs->at(i)->CntrlPreds->at(idx_) = fork;
				}

				fork->CntrlPreds->push_back(enode);
				enode->CntrlSuccs->at(1) = fork;

				// AYA: 10/08/2023: tag only components fed from out0 of the LoopMux that contains both tag and data.. On the contrary, do not tag any components fed from out1 of the LoopMux which contains tag only without data
				if(fork->CntrlSuccs->at(0)->is_tagged)
					fork->is_tagged = true;
				else
					fork->is_tagged = false;


				enode_dag->push_back(fork);
			}
		}
	}
}

// STILL TODO!!!
// The purpose of this function is to tag the outer loop components fed from the ROB of the inner components using its loop's (i.e., the outer loop) LoopMux
void CircuitGenerator::tag_loop_components() {

}