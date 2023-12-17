/*
 * Authors: Ayatallah Elakhras
 * 			
 */
#include "ElasticPass/CircuitGenerator.h"
#include<iterator>
#include<algorithm>

void loop_master_from_input(std::string& phi_type_str, std::string& phi_id_str) {
    std::string filename = TAG_INFO_PATH;
    std::ifstream file(filename, std::ifstream::in);

    if (!file) {
        cerr << "Error opening " << filename << " use default loop master value which is phi_0..." << endl;
        phi_type_str = "_";
        phi_id_str = "0";
        return;
    }

    string line;
    assert(getline (file, line));
    assert(getline (file, line));
    assert(getline (file, phi_type_str));
    assert(getline (file, phi_id_str));
}


// AYA: 27/09/2023
// TEMPORARIly assuming that an if-then-else is made up of a single Mux, so we break once we find one and we connect the Cmerge cond output to sink
void CircuitGenerator::convert_if_else_cmerge() {
    ENode* if_else_master = nullptr;

    for(auto& enode: *enode_dag) {

         if((enode->type == Phi_ || enode->type == Phi_n || enode->type == Phi_c ) && !enode->is_merge_init && !enode->is_shannons_mux) {
            if(BBMap->at(enode->BB)->is_loop_header)
                continue; // skip muxes at loop headers

            assert(enode->isMux);
            
            if_else_master = enode;
            break;
        }
    }

    assert(if_else_master != nullptr);

    if(if_else_master != nullptr) {  // if this enode happens to be the if_else_master
        // erase its condition input AND change its type to CMerge

        //But, first store it inside the object in an extra ENode field
        if_else_master->old_cond_of_if_else_merge = if_else_master->CntrlPreds->at(0);

        auto pos = std::find(if_else_master->CntrlPreds->at(0)->CntrlSuccs->begin(), if_else_master->CntrlPreds->at(0)->CntrlSuccs->end(), if_else_master);
        assert(pos != if_else_master->CntrlPreds->at(0)->CntrlSuccs->end());
        if_else_master->CntrlPreds->at(0)->CntrlSuccs->erase(pos);

        if_else_master->CntrlPreds->erase(if_else_master->CntrlPreds->begin());

        if_else_master->isMux = false;
        if_else_master->isCntrlMg = true;
        if_else_master->is_if_else_cmerge = true;

        if_else_master->cmerge_data_succs = new std::vector<ENode*>;
        if_else_master->cmerge_control_succs = new std::vector<ENode*>;

        // remove its succs from the data network and temporarily place them in two separate vectors to mark them during addFork
        assert(if_else_master->CntrlSuccs->size() > 0);
        for(int k = 0; k < if_else_master->CntrlSuccs->size(); k++) {
            if_else_master->cmerge_data_succs->push_back(if_else_master->CntrlSuccs->at(k));
        }
        if_else_master->CntrlSuccs->clear();

        // AYA: 30/09/2023: storing the condition node of the Branches of this if-then-else inside it because we lose the connection later as soon as we insert the TAAGER
        for(auto& enode_3 : *enode_dag) {
            // push all Branches that have the same condition as the if_else_cmerge
            if((enode_3->type == Branch_n && (enode_3->CntrlPreds->at(1) == if_else_master->old_cond_of_if_else_merge || enode_3->CntrlPreds->at(1)->CntrlPreds->at(0) == if_else_master->old_cond_of_if_else_merge))) {
                enode_3->old_cond_of_if_else_branch = enode_3->CntrlPreds->at(1);
            } else if( (enode_3->type == Branch_c && (enode_3->CntrlPreds->at(0) == if_else_master->old_cond_of_if_else_merge || enode_3->CntrlPreds->at(0)->CntrlPreds->at(0) == if_else_master->old_cond_of_if_else_merge))) {
                enode_3->old_cond_of_if_else_branch = enode_3->CntrlPreds->at(0);
            }
        }

    } 
}



// AYA: 16/09/2023
// Because I currently do not have a specific strategy to decide which specific Mux among all Muxes of 1 loop should become the master and be the Cmerge,
        // I'm just choosing the one that feeds the multiplier
void CircuitGenerator::convert_loop_cmerge(bool ignore_outer_most_loop) {
    std::ofstream dbg_file;
    dbg_file.open("AYA_converting_loop_cmerge.txt");

    // PLan: 
    // 1st) loop over all Muxes at loop headers and search for a Mux that feeds a multiplier, and convert it to CMerge
    // 2nd) LOop over the reamining MUxes at the loop header of this particular loop, and call removeINIT() which internally connects the Mux directly to the condition of the loop: will leave it this way temporarily
                // then let them be fed with the 2nd output of the CMerge instead of from the loop condition!!

    for(auto& enode: *enode_dag) {
        ENode* loop_master = nullptr;

        if((enode->type == Phi_ || enode->type == Phi_n || enode->type == Phi_c ) && !enode->is_merge_init && !enode->is_shannons_mux) {

            // AYA: 19/09/2023: skip outer loops
            /*if(BBMap->at(enode->BB)->loop != nullptr && ignore_outer_most_loop) {
                if(BBMap->at(enode->BB)->loop->getParentLoop() == nullptr /*|| !(BBMap->at(enode->BB)->is_inner_most_loop)*//*)
                    continue;
            }*/

            if(BBMap->at(enode->BB)->is_loop_header) {   // check if this MUX is at a loop header
                // 1st: let's do some sanity checks
                assert(enode->isMux);
                if(enode->type == Phi_ || enode->type == Phi_n) {
                    assert(enode->CntrlPreds->size() == 3);
                } else {
                    assert(enode->JustCntrlPreds->size() == 2 || enode->CntrlOrderPreds->size() == 2);    
                }

                // check the succs of this enode
               /* for(int i = 0; i < enode->CntrlSuccs->size(); i++) {
                    // THIS CONDITION SHOULD BE CHANGED DEPENDING ON THE BENCHMARK OR ONCE WE HAVE A FIXED STRATEGY FOR DECIDING THE MASTER FOR A PARTICULAR LOOP
                    if( (enode->CntrlSuccs->at(i)->Name == "fadd") /* && enode->CntrlSuccs->at(i)->id == 16) ||
                          (enode->CntrlSuccs->at(i)->Name == "fadd" && enode->CntrlSuccs->at(i)->id == 41) ||
                          enode->CntrlSuccs->at(i)->Name == "mul" ) {
                        // check if this enode is eventually fed from this mul
                        if(enode->CntrlPreds->at(1)->type == Branch_n) {
                            if(enode->CntrlPreds->at(1)->CntrlPreds->at(0) == enode->CntrlSuccs->at(i)) {
                                loop_master = enode;
                                break;
                            }
                        } else {
                            assert(enode->CntrlPreds->at(2)->type == Branch_n);
                             if(enode->CntrlPreds->at(2)->CntrlPreds->at(0) == enode->CntrlSuccs->at(i)) {
                                loop_master = enode;
                                break;
                            }
                        }
                    }
                } */

                // AYA: 09/12/2023
                std::string phi_type_str, phi_id_str;
                loop_master_from_input(phi_type_str, phi_id_str);

                int phi_id = std::stoi(phi_id_str);
                assert(phi_id >= 0);

                node_type phi_type;
                if(phi_type_str == "_") {
                    phi_type = Phi_;
                } else if(phi_type_str == "_n"){
                    phi_type = Phi_n;
                } else {
                    assert(phi_type_str == "_c");
                    phi_type = Phi_c;
                }
                /////////////////////////////

                if((enode->type == phi_type && enode->id == phi_id))// || (enode->type == Phi_ && enode->id == 31))
                    loop_master = enode;
                
                // AYA: 17/12/2023: moved the following to happen below to ensure that it happens only to Muxes in the same loop as the loop master!!
                /*// in any case regardless whether this enode is the loop master or not, call the following two functions
                removeINIT(dbg_file, enode);
                // let's make sure that the convention of having the 0th data input coming from outside is satisfied
                fixLoopMuxes_inputs(enode);*/

                if(loop_master != nullptr) {  // if this enode happens to be the loop_master
                    // erase its condition input AND change its type to CMerge
                    auto pos = std::find(loop_master->CntrlPreds->at(0)->CntrlSuccs->begin(), loop_master->CntrlPreds->at(0)->CntrlSuccs->end(), loop_master);
                    assert(pos != loop_master->CntrlPreds->at(0)->CntrlSuccs->end());
                    loop_master->CntrlPreds->at(0)->CntrlSuccs->erase(pos);

                    loop_master->CntrlPreds->erase(loop_master->CntrlPreds->begin());

                    loop_master->isMux = false;
                    loop_master->isCntrlMg = true;
                    loop_master->is_data_loop_cmerge = true;

                    loop_master->cmerge_data_succs = new std::vector<ENode*>;
                    loop_master->cmerge_control_succs = new std::vector<ENode*>;

                    // remove its succs from the data network and temporarily place them in two separate vectors to mark them during addFork
                    assert(loop_master->CntrlSuccs->size() > 0);
                    for(int k = 0; k < loop_master->CntrlSuccs->size(); k++) {
                        loop_master->cmerge_data_succs->push_back(loop_master->CntrlSuccs->at(k));
                    }
                    loop_master->CntrlSuccs->clear();

                    // AYA: 17/12/2023
                    // let's make sure that the convention of having the 0th data input coming from outside is satisfied
                    bool found_external_pred = false;
                    int extrenal_pred_idx = -1;
                    if(loop_master->CntrlPreds->at(0)->BB != nullptr) {
                        if(BBMap->at(loop_master->CntrlPreds->at(0)->BB)->loop != BBMap->at(loop_master->BB)->loop) {
                            found_external_pred = true;
                            extrenal_pred_idx = 0;
                        }
                    } 
                    if(!found_external_pred) {
                        assert(loop_master->CntrlPreds->at(1)->BB != nullptr);
                        assert(BBMap->at(loop_master->CntrlPreds->at(1)->BB)->loop != BBMap->at(loop_master->BB)->loop);
                        found_external_pred = true;
                        extrenal_pred_idx = 1;
                    }

                    assert(found_external_pred && extrenal_pred_idx != -1);
                    if(extrenal_pred_idx != 0) {
                        assert(extrenal_pred_idx == 1);
                        // swap the two preds
                        ENode* temp = loop_master->CntrlPreds->at(0);
                        loop_master->CntrlPreds->at(0) = loop_master->CntrlPreds->at(1);
                        loop_master->CntrlPreds->at(1) = temp;
                    }


                } 
            }
        }
         
    }

    // AYA: 17/12/12023
    bool found_at_least_one_loop_master = false;
    for(auto& loop_master :*enode_dag) {
        if(!loop_master->isCntrlMg)   // allow only the cntrl merges to pass
           continue; 
        
        assert(loop_master->type == Phi_ || loop_master->type == Phi_n || loop_master->type == Phi_c);  // sanity check

        found_at_least_one_loop_master = true;

        // once we made sure that we converted one of the Muxes of the loop into CMerge, loop on the rest of the remaining Muxes to convert their select
        for(auto& enode :*enode_dag) {
            // AYA: 17/12/12023
            ///////////////////
            if(enode->BB == nullptr)
                continue;

            if(BBMap->at(enode->BB)->loop == nullptr)
                continue;

            if(enode->BB != loop_master->BB)  // we want phis that are in the same BB as that of the chosen loop master so skip the rest
                continue;

            if((enode->type == Phi_ || enode->type == Phi_n || enode->type == Phi_c ) && !enode->is_merge_init && !enode->is_shannons_mux
                    && enode->isMux) {

                assert(BBMap->at(enode->BB)->is_loop_header);  // sanity check

                removeINIT(dbg_file, enode);
                // let's make sure that the convention of having the 0th data input coming from outside is satisfied
                fixLoopMuxes_inputs(enode);

                auto pos = std::find(enode->CntrlPreds->at(0)->CntrlSuccs->begin(), enode->CntrlPreds->at(0)->CntrlSuccs->end(), enode);
                assert(pos != enode->CntrlPreds->at(0)->CntrlSuccs->end());
                enode->CntrlPreds->at(0)->CntrlSuccs->erase(pos);

                enode->CntrlPreds->at(0) = loop_master;
                loop_master->cmerge_control_succs->push_back(enode);
            }

            // AYA: 17/12/2023: replaced the following commented code wiht the above code
            /*if((enode->type == Phi_ || enode->type == Phi_n || enode->type == Phi_c ) && !enode->is_merge_init && !enode->is_shannons_mux
                    && enode->isMux) {
                 // AYA: 19/09/2023: skip outer loops
                //if(BBMap->at(enode->BB)->loop != nullptr && ignore_outer_most_loop) {
                //    if(BBMap->at(enode->BB)->loop->getParentLoop() == nullptr)
                //        continue;
                //}
                
                if(BBMap->at(enode->BB)->is_loop_header) {   // check if this MUX is at a loop header
                    // 1st: let's do some sanity checks
                    if(enode->type == Phi_ || enode->type == Phi_n) {
                        assert(enode->CntrlPreds->size() == 3);
                    } else {
                        assert(enode->JustCntrlPreds->size() == 2 || enode->CntrlOrderPreds->size() == 2);    
                    }

                      // search for a loop master (i.e., a Cmerge in the same loop header BB)
                    ENode* found_loop_master = nullptr;
                    for(auto& enode_2 :*enode_dag){
                        if(enode_2->BB == enode->BB && enode_2->isCntrlMg) {
                            assert(enode_2->is_data_loop_cmerge);
                            found_loop_master = enode_2;
                            break;
                        }
                    }
                    assert(found_loop_master != nullptr);

                    // AYA: 17/12/2023: used to be above but this was wrong in the case of loop nests that have a depth greater than 2
                    removeINIT(dbg_file, enode);
                    // let's make sure that the convention of having the 0th data input coming from outside is satisfied
                    fixLoopMuxes_inputs(enode);

                    auto pos = std::find(enode->CntrlPreds->at(0)->CntrlSuccs->begin(), enode->CntrlPreds->at(0)->CntrlSuccs->end(), enode);
                    assert(pos != enode->CntrlPreds->at(0)->CntrlSuccs->end());
                    enode->CntrlPreds->at(0)->CntrlSuccs->erase(pos);

                    enode->CntrlPreds->at(0) = found_loop_master;
                    found_loop_master->cmerge_control_succs->push_back(enode);

                }

            }*/

        }

    }

    assert(found_at_least_one_loop_master); // sanity check: must have found at least one loop_master!!

}

ENode* CircuitGenerator::insert_LoopMux_synch(BBNode* bbnode) {
    for(auto& enode: *enode_dag) {
        if(enode->BB == bbnode->BB)
            assert(enode->type != LoopMux_Synch);
    }
    ENode* synch = new ENode(LoopMux_Synch, "Synch", bbnode->BB);
    synch->id = loop_mux_synch_id++;

    enode_dag->push_back(synch);

    return synch;
}

void CircuitGenerator::connect_synch_to_LoopMux(ENode* one_loop_mux, ENode* synch) {
    if(one_loop_mux->type == Loop_Phi_n) {
            assert(one_loop_mux->CntrlPreds->size() == 3);

            synch->CntrlPreds->push_back(one_loop_mux->CntrlPreds->at(1));
            // the in0 of the one_loop_mux can not be a data Branch but it could be a control Branch
            assert(one_loop_mux->CntrlPreds->at(1)->type != Branch_c);
            if(one_loop_mux->CntrlPreds->at(1)->type == Branch_n) {
                // the one_loop_mux should be either in the true_succs or the false_succs
                auto pos_true = std::find(one_loop_mux->CntrlPreds->at(1)->true_branch_succs->begin(), one_loop_mux->CntrlPreds->at(1)->true_branch_succs->end(), one_loop_mux);
                if((pos_true != one_loop_mux->CntrlPreds->at(1)->true_branch_succs->end())) {
                    int idx = pos_true - one_loop_mux->CntrlPreds->at(1)->true_branch_succs->begin();
                    one_loop_mux->CntrlPreds->at(1)->true_branch_succs->at(idx) = synch;

                } else {
                    auto pos_false = std::find(one_loop_mux->CntrlPreds->at(1)->false_branch_succs->begin(), one_loop_mux->CntrlPreds->at(1)->false_branch_succs->end(), one_loop_mux);
                    assert((pos_false != one_loop_mux->CntrlPreds->at(1)->false_branch_succs->end()));

                    int idx = pos_false - one_loop_mux->CntrlPreds->at(1)->false_branch_succs->begin();
                    one_loop_mux->CntrlPreds->at(1)->false_branch_succs->at(idx) = synch;
                }
            } else {
                auto pos__ = std::find(one_loop_mux->CntrlPreds->at(1)->CntrlSuccs->begin(), one_loop_mux->CntrlPreds->at(1)->CntrlSuccs->end(), one_loop_mux);
                assert(pos__ != one_loop_mux->CntrlPreds->at(1)->CntrlSuccs->end());
                int idx = pos__ - one_loop_mux->CntrlPreds->at(1)->CntrlSuccs->begin();
                one_loop_mux->CntrlPreds->at(1)->CntrlSuccs->at(idx) = synch;
            }

            synch->CntrlSuccs->push_back(one_loop_mux);
            one_loop_mux->CntrlPreds->at(1) = synch;
    } else {
        assert(one_loop_mux->type == Loop_Phi_c);
        std::vector<ENode*>* Preds;
        std::vector<ENode*>* Succs_of_Preds;
        std::vector<ENode*>* synch_Preds;
        std::vector<ENode*>* synch_Succs;
        if(one_loop_mux->JustCntrlPreds->size() > 0) {
            Preds = one_loop_mux->JustCntrlPreds;

            assert(Preds->at(0)->type != Branch_n);
            if(Preds->at(0)->type == Branch_c) {
                auto pos_true = std::find(Preds->at(0)->true_branch_succs_Ctrl->begin(), Preds->at(0)->true_branch_succs_Ctrl->end(), one_loop_mux);
                if((pos_true != Preds->at(0)->true_branch_succs_Ctrl->end())) {
                    Succs_of_Preds = Preds->at(0)->true_branch_succs_Ctrl;
                } else {
                    auto pos_false = std::find(Preds->at(0)->false_branch_succs_Ctrl->begin(), Preds->at(0)->false_branch_succs_Ctrl->end(), one_loop_mux);
                    assert((pos_false != Preds->at(0)->false_branch_succs_Ctrl->end()));
                    Succs_of_Preds = Preds->at(0)->false_branch_succs_Ctrl;
                }
            } else {
                assert(Preds->at(0)->JustCntrlSuccs->size() > 0);
                Succs_of_Preds = Preds->at(0)->JustCntrlSuccs;
            }

            synch_Preds = synch->JustCntrlPreds;
            synch_Succs = synch->JustCntrlSuccs;
        } else {
            assert(one_loop_mux->CntrlOrderPreds->size() > 0);
            Preds = one_loop_mux->CntrlOrderPreds;

            assert(Preds->at(0)->type != Branch_n);
            if(Preds->at(0)->type == Branch_c) {
                auto pos_true = std::find(Preds->at(0)->true_branch_succs_Ctrl_lsq->begin(), Preds->at(0)->true_branch_succs_Ctrl_lsq->end(), one_loop_mux);
                if((pos_true != Preds->at(0)->true_branch_succs_Ctrl_lsq->end())) {
                    Succs_of_Preds = Preds->at(0)->true_branch_succs_Ctrl_lsq;
                } else {
                    auto pos_false = std::find(Preds->at(0)->false_branch_succs_Ctrl_lsq->begin(), Preds->at(0)->false_branch_succs_Ctrl_lsq->end(), one_loop_mux);
                    assert((pos_false != Preds->at(0)->false_branch_succs_Ctrl_lsq->end()));
                    Succs_of_Preds = Preds->at(0)->false_branch_succs_Ctrl_lsq;
                }
            } else {
                assert(Preds->at(0)->CntrlOrderSuccs->size() > 0);
                Succs_of_Preds = Preds->at(0)->CntrlOrderSuccs;
            }

            synch_Preds = synch->CntrlOrderPreds;
            synch_Succs = synch->CntrlOrderSuccs;
        }

        synch_Preds->push_back(Preds->at(0));
        //synch->CntrlPreds->push_back(Preds->at(0));
        auto pos__ = std::find(Succs_of_Preds->begin(), Succs_of_Preds->end(), one_loop_mux);
        assert(pos__ != Succs_of_Preds->end());
        int idx = pos__ - Succs_of_Preds->begin();
        Succs_of_Preds->at(idx) = synch;
        //Succs_of_Preds->erase(pos__);
        //Preds->at(0)->CntrlSuccs->push_back(synch);

        synch_Succs->push_back(one_loop_mux);
        //synch->CntrlSuccs->push_back(one_loop_mux);
        Preds->at(0) = synch;
    }
}

/**
 * @brief This function inserts a Synchronizer component
 * @param 
 * @notes Note that it is needed ONLY if we will use the more flexible LoopMUX specifications that does not assume that the number of threads is divisible by the pragma N 
 */
void CircuitGenerator::synch_loopMux() {
    for(auto& enode: *enode_dag) {
        if(enode->type != Loop_Phi_n && enode->type != Loop_Phi_c)
            continue;   // skip if the enode is not a LoopMUX

        if(enode->is_loopMux_synchronized)
            continue;  // skip if the enode has been already handled by inserting a synchronizer at its input

        ENode* one_loop_mux = enode;

        // first, insert a new synchronizer in the BB of the one_loop_mux (assert that it can not ever be the case that there is a synchronizer component already inserted  in this BB)
        ENode* synch = insert_LoopMux_synch(BBMap->at(one_loop_mux->BB));

        // second, insert this synch between the in0 of one_loop_mux and the original component that was feeding it
        connect_synch_to_LoopMux(one_loop_mux, synch);
        one_loop_mux->is_loopMux_synchronized = true;

        for(auto& enode_2: *enode_dag) {
            if(enode_2->type != Loop_Phi_n && enode_2->type != Loop_Phi_c)
                continue;   // skip if the enode is not a LoopMUX 

            if(BBMap->at(enode_2->BB)->loop != BBMap->at(one_loop_mux->BB)->loop) 
                continue;  // skip if the LoopMUX is belonging to another loop (not the one of my one_Loop_mux)

            if(enode_2->is_loopMux_synchronized)
                continue;  // skip if the enode has been already handled by inserting a synchronizer at its input

            connect_synch_to_LoopMux(enode_2, synch);
            enode_2->is_loopMux_synchronized = true;
        }
    }
}

    
/**
 * @brief This function loops over all phis that are at the loop headers and ensures that the 0th data input of the MUX comes from outside the loop and the 1st data input comes from inside the loop
 *          It will be called inside the function that converts to a special_mux_type
 * @param 
 */
// TODO: check that this function works if the loop exit condition is an output of a MUX either because the loop has multiple exits or because it is a nested loop (towards the regeneration stuff!)
void CircuitGenerator::fixLoopMuxes_inputs(ENode* enode){
    ENode* mux_sel = enode->CntrlPreds->at(0);
    //std::vector<ENode*>* mux_data_inputs;  
    ENode* mux_in0 = nullptr;
    ENode* mux_in1 = nullptr;

    if(enode->type == Phi_c) {
        // check if the 0th data input is inside or outside the loop
        if(enode->JustCntrlPreds->size() > 0) {
            assert(enode->CntrlOrderPreds->size() == 0);
            //mux_data_inputs = enode->JustCntrlPreds;
            mux_in0 = enode->JustCntrlPreds->at(0);
            mux_in1 = enode->JustCntrlPreds->at(1);
        } else {
            assert(enode->CntrlOrderPreds->size() > 0);
            //mux_data_inputs = enode->CntrlOrderPreds;
            mux_in0 = enode->CntrlOrderPreds->at(0);
            mux_in1 = enode->CntrlOrderPreds->at(1);
        }
    } else {
        assert(enode->type == Phi_n || enode->type == Phi_);
        assert(enode->CntrlPreds->size() == 3);
        //mux_data_inputs = enode->CntrlPreds;

        mux_in0 = enode->CntrlPreds->at(1);
        mux_in1 = enode->CntrlPreds->at(2);
    }

    assert(mux_in0 != nullptr && mux_in1 != nullptr);

    if(BBMap->at(enode->BB)->loop->contains(mux_in0->BB)) {
        assert(!BBMap->at(enode->BB)->loop->contains(mux_in1->BB));

        // sanity check, the flag of advanced_component must be true indicating that the vector of is_negated input is filled with the signs of the input
        assert(enode->is_advanced_component);
        assert(enode->is_negated_input->size() == 3);

        // change the sign of the SEL
        if(enode->is_negated_input->at(0)) {
            enode->is_negated_input->at(0) = false;
        } else {
            enode->is_negated_input->at(0) = true;
        }

        // swap in0 and in1
        if(enode->type == Phi_c) {
            if(enode->JustCntrlPreds->size() > 0) {
                ENode* temp = enode->JustCntrlPreds->at(0);
                enode->JustCntrlPreds->at(0) = enode->JustCntrlPreds->at(1);
                enode->JustCntrlPreds->at(1) = temp;
            } else {
                ENode* temp = enode->CntrlOrderPreds->at(0);
                enode->CntrlOrderPreds->at(0) = enode->CntrlOrderPreds->at(1);
                enode->CntrlOrderPreds->at(1) = temp;
            }
        } else {
            ENode* temp = enode->CntrlPreds->at(1);
            enode->CntrlPreds->at(1) = enode->CntrlPreds->at(2);
            enode->CntrlPreds->at(2) = temp;
        }
        /*ENode temp = *mux_in0;
        *mux_in0 = *mux_in1;
        *mux_in1 = temp;*/
    } 

}

/**
 * @brief This function connects the loopMUX directly to the loop exit condition and deletes the INIT and the constant that was feeding the INIT. 
 *          The idea is that instead of killing the original stuff of FPL'22, I just add extra functions to remove them later so that it is easier for us to get back to FPL'22 whenever we want
 * @param 
 */
void CircuitGenerator::removeINIT(std::ofstream& dbg_file, ENode* enode){
    // 1st assert that the condition (SEL) input of the enode is an INIT
    ENode* mux_init = enode->CntrlPreds->at(0);

    //dbg_file << "\nFor the MUX in BB" << BBMap->at(mux_init->BB)->Idx + 1 << " called " << getNodeDotNameNew(enode) << " and is of type " << getNodeDotTypeNew(enode) << "its SEL is a node of type: " 
               // << getNodeDotTypeNew(mux_init) << "\n";

    assert(mux_init->type == Phi_n);
    assert(mux_init->is_merge_init);

    // 2nd identify the input of the INIT that is a loop condition and assert that the other input is a constant and delete it
    assert(mux_init->CntrlPreds->size() == 2);
    ENode* init_const = nullptr;
    ENode* init_condition = nullptr;
    int cond_idx_init = -1;
    if(mux_init->CntrlPreds->at(0)->type == Cst_){
        init_const = mux_init->CntrlPreds->at(0);
        init_condition = mux_init->CntrlPreds->at(1);
        cond_idx_init = 1;

        /*dbg_file << "\n********************** Inside a new MUX *****************************\n";
        dbg_file << "The init_cond has " << init_condition->CntrlSuccs->size() << " succs and " << init_condition->CntrlPreds->size() << "preds.\n";
        dbg_file << "Here is a list of the enodes that are succs of the init_condition: \n";
        for(int i = 0; i < init_condition->CntrlSuccs->size(); i++) {
            dbg_file << getNodeDotTypeNew(init_condition->CntrlSuccs->at(i)) << ", ";
            if(mux_init == init_condition->CntrlSuccs->at(i)) {
                dbg_file << "FOUND IT!!\n";
            }
        }
        dbg_file <<"\n";*/

    } else {
        assert(mux_init->CntrlPreds->at(1)->type == Cst_);
        init_const = mux_init->CntrlPreds->at(1);
        init_condition = mux_init->CntrlPreds->at(0);
        cond_idx_init = 0;

        /*dbg_file << "\n********************** Inside a new MUX *****************************\n";
        dbg_file << "The init_cond has " << init_condition->CntrlSuccs->size() << " succs and " << init_condition->CntrlPreds->size() << "preds.\n";
        dbg_file << "Here is a list of the enodes that are succs of the init_condition: \n";
        for(int i = 0; i < init_condition->CntrlSuccs->size(); i++) {
            dbg_file << getNodeDotTypeNew(init_condition->CntrlSuccs->at(i)) << ", ";
            if(mux_init == init_condition->CntrlSuccs->at(i)) {
                dbg_file << "FOUND IT!!\n";
            }
        }
        dbg_file <<"\n";*/

    }
    assert(init_const != nullptr && init_condition != nullptr && cond_idx_init != -1);

    // erase the mux_init from the succs of the init_const only if this mux_init has no remaining succs other than the current enode
    if(mux_init->CntrlSuccs->size() == 1) {
        auto pos__ = std::find(init_const->CntrlSuccs->begin(), init_const->CntrlSuccs->end(), mux_init);
        assert(pos__ != init_const->CntrlSuccs->end());
        init_const->CntrlSuccs->erase(pos__);
    }

    // if the constant has no succs other than the INIT (AND if the INIT does not feed anything else), cut the connection between it and START and the INIT and delete it
    if(init_const->CntrlSuccs->size() == 0 && mux_init->CntrlSuccs->size() == 1) {
        // cut the connection between the predecessor of the init_const (i.e., START) and the init_const
        assert(init_const->CntrlPreds->size() == 0 &&  init_const->CntrlOrderPreds->size() == 0);
        assert(init_const->JustCntrlPreds->size() == 1);
        assert(init_const->JustCntrlPreds->at(0)->type == Start_);
        
        auto pos = std::find(init_const->JustCntrlPreds->at(0)->JustCntrlSuccs->begin(), init_const->JustCntrlPreds->at(0)->JustCntrlSuccs->end(), init_const);
        assert(pos != init_const->JustCntrlPreds->at(0)->JustCntrlSuccs->end());
        // erase the init_const from the succs of START!
        init_const->JustCntrlPreds->at(0)->JustCntrlSuccs->erase(pos);

        // clear the preds and succs of the init_const 
        init_const->JustCntrlPreds->clear();
        init_const->CntrlSuccs->clear();

        assert(init_const->CntrlSuccs->size() == 0 && init_const->CntrlPreds->size() == 0 && init_const->JustCntrlPreds->size() == 0 &&
                     init_const->JustCntrlSuccs->size() == 0 && init_const->CntrlOrderPreds->size() == 0 && init_const->CntrlOrderSuccs->size() == 0);
        // erase the init_const from the enode_dag
        auto pos_const = std::find(enode_dag->begin(), enode_dag->end(), init_const);
        assert(pos_const != enode_dag->end());
        enode_dag->erase(pos_const);
    }

    // Towards deleting the INIT

    // I need to label my MUX (i.e., enode) as an "advanced_component" and set its is_negated_input vector
    enode->is_advanced_component = true;
    // sanity checks
    assert(mux_init->is_advanced_component && mux_init->is_negated_input->size() == 2);
    enode->is_negated_input->push_back(mux_init->is_negated_input->at(cond_idx_init));
    // the 2 data inputs of the MUX are never negated!
    enode->is_negated_input->push_back(false);
    enode->is_negated_input->push_back(false);
  
    // erase the enode from the succs of the mux_init
    auto pos_ = std::find(mux_init->CntrlSuccs->begin(), mux_init->CntrlSuccs->end(), enode);
    assert(pos_ != mux_init->CntrlSuccs->end());
    mux_init->CntrlSuccs->erase(pos_);

    // push back the enode to the successors of the loop condition because there are multiple enodes and the loop condition is feeding only one INIT
            // and we will erase the connection to the INIT once in the end
    init_condition->CntrlSuccs->push_back(enode);
    if(mux_init->CntrlSuccs->size() == 0) {
        // find the INIT in the successors of the loop condition
        auto pos = std::find(init_condition->CntrlSuccs->begin(), init_condition->CntrlSuccs->end(), mux_init);
        assert(pos != init_condition->CntrlSuccs->end());
        init_condition->CntrlSuccs->erase(pos);
    }

    // replace the connection between the INIT and the enode with a direct connection between the enode and the init_condition
    enode->CntrlPreds->at(0) = init_condition;

    // check if the INIT has no other succs (it might be already connected to another MUX that still was not called in this function so must do this check), cut the connection between it and the constant and delete it!
    if(mux_init->CntrlSuccs->size() == 0) {
        mux_init->CntrlSuccs->clear();
        mux_init->CntrlPreds->clear();

        assert(mux_init->CntrlSuccs->size() == 0 && mux_init->CntrlPreds->size() == 0);
        // erase the mux_init from the enode_dag
        auto pos = std::find(enode_dag->begin(), enode_dag->end(), mux_init);
        assert(pos != enode_dag->end());
        enode_dag->erase(pos);
    } 

    
}

/**
 * @brief This function converts the type of the MUX at the loop header to a new type Loop_Phi_n to be instantiate the SPECIAL_MUX type in the backend. IN the same spirit of the above function,
 *          the idea is that instead of killing the original stuff of FPL'22, I just add extra functions to remove them later so that it is easier for us to get back to FPL'22 whenever we want
 * @param 
 * @assumptions It is important to note that this function assumes that any Phi of the three types is at the loop header if it is a loop MUX
 */
void CircuitGenerator::convert_to_special_mux(){
    std::ofstream dbg_file;
    dbg_file.open("AYA_checking_lopp_condition.txt");
    //dbg_file << "\nChecking if the flag is_merge_init is not true for all Merges used as INIT\n";
    for(auto& enode: *enode_dag) {
        if((enode->type == Phi_ || enode->type == Phi_n || enode->type == Phi_c ) && !enode->is_merge_init && !enode->is_shannons_mux) {
            if(BBMap->at(enode->BB)->is_loop_header) {   // check if this MUX is at a loop header
                // 1st: let's do some sanity checks
                assert(enode->isMux);
                if(enode->type == Phi_ || enode->type == Phi_n) {
                    assert(enode->CntrlPreds->size() == 3);
                } else {
                    assert(enode->JustCntrlPreds->size() == 2 || enode->CntrlOrderPreds->size() == 2);    
                }

                // 2nd: let's remove the INIT and its constant and make a direct connection between the loop condition and the SEL of the Phi
                removeINIT(dbg_file, enode);

                // 3rd: let's make sure that the convention of having the 0th data input coming from outside is satisfied
                fixLoopMuxes_inputs(enode);

                // 4th: let's convert the Phi to my special_mux type: Phi_n and Phi_ will be mapped to one type that will get translated to the special_mux with some data bits, whereas Phi_c will be mapped to another type to be translated to the special_mux as well but with 0 data bits..
                if(enode->type == Phi_ || enode->type == Phi_n) {
                    enode->type = Loop_Phi_n;
                } else {
                    enode->type = Loop_Phi_c;
                }
                enode->id = loop_phi_id++;
            }
        }
         
    }
}

// ON A SIDE NOTE, IN TERMS OF PRIORITIZING THE RULES OF TRANSFORMATIONS IN CASE SEVERAL OF THEM ARE APPLICABLE AT ONE POINT IN TIME, 
    // I THINK THE LOWEST PRIORITY WOULD BE THE REGEN_SUPP TO SUPP_REGEN?????

 // IMP note to self: A consumer can be fed with a Branch in cases of more consumed than produced, but in this case, there is no regenerate
                // and the loop_mux never feeds this Branch directly (i.e., it has to be fed with an operation that produces a new value every iteration)
void CircuitGenerator::apply_term_rewriting(networkType network_flag) {
    node_type loop_mux_type;
    node_type supp_type;
   
    switch(network_flag) {
        case data:
            loop_mux_type = Loop_Phi_n;
            supp_type = Branch_n;
        break;
        case constCntrl:
        case memDeps:
            loop_mux_type = Loop_Phi_c;
            supp_type = Branch_c;
    }

    // I'M NOT SURE THAT THIS IS NECESSARY THOUGH!!!!
    // MAYBE LATER I CHANGE THIS TO CHECKING ANOTHER ARRAY THAT CONTAINS THE GLOBAL PRODUCERS AND CONSUMERS AND THIS WILL ALSO CHANGE THE SUCCS TO KEEP CHECKING UNTIL YOU FIND A SPECIFIC CONSUMER!!
  
    for(auto& enode: *enode_dag) { 
        // 1st check for the transformation of REGEN_SUPP to SUPP_REGEN
        if(!(enode->is_regen_mux && enode->type == loop_mux_type))
            continue;
        ENode* loop_mux = enode;
        std::vector<ENode*>* loop_mux_succs;
        switch(network_flag) {
            case data:
                loop_mux_succs = enode->CntrlSuccs;
            break;

            case constCntrl:
                loop_mux_succs = enode->JustCntrlSuccs;
            break;

            case memDeps:
                loop_mux_succs = enode->CntrlOrderSuccs;
        }
        assert(loop_mux_succs != nullptr);

        // loop over the consumers of this regenerate loop_mux producer
        for(int i = 0; i < loop_mux_succs->size(); i++) {
            if(loop_mux_succs->at(i)->type != supp_type) 
                continue;
            ENode* supp = loop_mux_succs->at(i);
            std::vector<ENode*>* supp_true_succs;
            std::vector<ENode*>* supp_false_succs;
            switch(network_flag) {
                case data:
                    supp_true_succs = supp->true_branch_succs;
                    supp_false_succs = supp->false_branch_succs;
                break;

                case constCntrl:
                    supp_true_succs = supp->true_branch_succs_Ctrl;
                    supp_false_succs = supp->false_branch_succs_Ctrl;
                break;

                case memDeps:
                    supp_true_succs = supp->true_branch_succs_Ctrl_lsq;
                    supp_false_succs = supp->false_branch_succs_Ctrl_lsq;
            }

            // if the branch is not feeding the loop_mux enode (i.e., if it is not the Branch that is part of the regeneration)
            auto pos_true = std::find(supp_true_succs->begin(), supp_true_succs->end(), loop_mux);
            auto pos_false = std::find(supp_false_succs->begin(), supp_false_succs->end(), loop_mux);
            if(pos_true == supp_true_succs->end() && pos_false == supp_false_succs->end()) {
                // at this point we have a loopMux (representing REGENERATE) and SUPP and we would like to swap them and add a TMFO for their conditions
                    // so we call the following function to do the job
                convert_REGEN_SUPP(network_flag, loop_mux, supp, i);
            }
        }
    }
}

// IMP NOTE: this function works only with LoopMUX because it assumes that the condition of the Regen MUX is the same as the condition of the Regen Branch!!
    // To make it work with the old MUX + INIT, we need to see what to connect to TMFO between the loop condition and the INIT!!!
        // Specifically, this can be fixed by passing the TMFO to the INIT input instead of directly to the MUX!!!!

// ON A SIDE NOTE, FOR THE REMOVE_REDUN_BRANCH, I CAN TWEAK THE EXISTING ONE TO COMMENT EVEYRHTING EXCEPT THE CONDITION THAT COMBINES THE SUPPRESSES
    // THAT ARE FED BY THE SAME PRODUCER AND HAVE THE SAME CONDITION.. ONYL ADD TO IT A CHECK THAT ALL OF ITS CONSUMERS ARE IN THE SAME BB (OTHERWISE DO NOT COMBINE THE SUPPRESSES FOR NOW)
void CircuitGenerator::convert_REGEN_SUPP(networkType network_flag, ENode* loop_mux, ENode* supp, int idx_supp_in_mux_succs) {
    // 1st identify the succs and preds arrays of each of the loop_mux and supp
    std::vector<ENode*>* loop_mux_succs;
    std::vector<ENode*>* loop_mux_preds;

    std::vector<ENode*>* supp_true_succs;
    std::vector<ENode*>* supp_false_succs;
    std::vector<ENode*>* supp_preds;

    switch(network_flag) {
        case data:
            loop_mux_succs = loop_mux->CntrlSuccs;
            loop_mux_preds = loop_mux->CntrlPreds;
            supp_true_succs = supp->true_branch_succs;
            supp_false_succs = supp->false_branch_succs;
            supp_preds = supp->CntrlPreds;
        break;

        case constCntrl:
            loop_mux_succs = loop_mux->JustCntrlSuccs;
            loop_mux_preds = loop_mux->JustCntrlPreds;
            supp_true_succs = supp->true_branch_succs_Ctrl;
            supp_false_succs = supp->false_branch_succs_Ctrl;
            supp_preds = supp->JustCntrlPreds;
        break;

        case memDeps:
            loop_mux_succs = loop_mux->CntrlOrderSuccs;
            loop_mux_preds = loop_mux->CntrlOrderPreds;
            supp_true_succs = supp->true_branch_succs_Ctrl_lsq;
            supp_false_succs = supp->false_branch_succs_Ctrl_lsq;
            supp_preds = supp->CntrlOrderPreds;
    }

    // IMP to note: I assume here that Branches are all SUPPRESSes meaning that they have succs either in the true array or the false array but never both
    assert((supp_true_succs->size() > 0 && supp_false_succs->size() == 0) || (supp_true_succs->size() == 0 && supp_false_succs->size() > 0));

    // given the above assumption, check if the succs of the supp are in the true side or the false side
    std::vector<ENode*>* supp_succs;
    if(supp_true_succs->size() > 0) {
        supp_succs = supp_true_succs;
    } else {
        assert(supp_false_succs->size() > 0);
        supp_succs = supp_false_succs;
    }

    // 2nd loop over the succs of the Branch and add them all to the succs of the enode such that the very first succ is put in place of the Branch
    loop_mux_succs->at(idx_supp_in_mux_succs) = supp_succs->at(0);
    for(int i = 1; i < supp_succs->size(); i++) {
        loop_mux_succs->push_back(supp_succs->at(i));
    }
    // let the loop_mux enode replace the supp in the preds of each succ of the supp!!
    for(int i = 0; i < supp_succs->size(); i++) {
        std::vector<ENode*>* supp_succs_preds;
        switch(network_flag) {
            case data:
                supp_succs_preds = supp_succs->at(i)->CntrlPreds;
                break;

            case constCntrl:
                supp_succs_preds = supp_succs->at(i)->JustCntrlPreds;
                break;

            case memDeps:
                supp_succs_preds = supp_succs->at(i)->CntrlOrderPreds;
        }
        auto pos = std::find(supp_succs_preds->begin(), supp_succs_preds->end(), supp);
        assert(pos != supp_succs_preds->end());
        int idx = pos - supp_succs_preds->begin();
        supp_succs_preds->at(idx) = loop_mux;    
    }

    // 3rd the cons_branch should be placed between the loop_mux and its pred that comes from outside of the loop 
                    // and the cons_branch should have the loop_mux as its only succ
                // identify the loop_mux pred that comes from outside the loop
    // making sure that in0 comes from outside

    ENode* loop_mux_outside_pred;
    std::vector<ENode*>* loop_mux_outside_pred_succs;

    if(network_flag == data) {
        assert(!BBMap->at(loop_mux->BB)->loop->contains(loop_mux_preds->at(1)->BB));  // (i.e., in0 of the Mux should come from outside the loop)
        //assert(loop_mux_preds->at(1)->type != Branch_n && loop_mux_preds->at(1)->type != Branch_c);   // TEMPORARY ASSUMING THAT IT CAN NOT BE A BRANCH TO AVOID CHECKING THE SUCC ARRAYS OF A BRANCH...

        loop_mux_outside_pred = loop_mux_preds->at(1);

        if(loop_mux_preds->at(0)->type == Branch_n) {
            // search for the loop_mux in its true succs
            auto pos_ = std::find(loop_mux_preds->at(0)->true_branch_succs->begin(), loop_mux_preds->at(0)->true_branch_succs->end(), loop_mux);
            if(pos_ != loop_mux_preds->at(0)->true_branch_succs->end()) {
                loop_mux_outside_pred_succs = loop_mux_preds->at(0)->true_branch_succs;
            } else {
                // search for the loop_mux in its false succs
                auto pos_ = std::find(loop_mux_preds->at(0)->false_branch_succs->begin(), loop_mux_preds->at(0)->false_branch_succs->end(), loop_mux);
                assert(pos_ != loop_mux_preds->at(0)->false_branch_succs->end()); // it must be in the false succ
                loop_mux_outside_pred_succs = loop_mux_preds->at(0)->false_branch_succs;
            }
        } else {
            loop_mux_outside_pred_succs = loop_mux_outside_pred->CntrlSuccs;
        }

    } else {
        assert(!BBMap->at(loop_mux->BB)->loop->contains(loop_mux_preds->at(0)->BB));  

        loop_mux_outside_pred = loop_mux_preds->at(0);

        if(network_flag == constCntrl) {
            if(loop_mux_preds->at(0)->type == Branch_c) {
                // search for the loop_mux in its true succs
                auto pos_ = std::find(loop_mux_preds->at(0)->true_branch_succs_Ctrl->begin(), loop_mux_preds->at(0)->true_branch_succs_Ctrl->end(), loop_mux);
                if(pos_ != loop_mux_preds->at(0)->true_branch_succs_Ctrl->end()) {
                    loop_mux_outside_pred_succs = loop_mux_preds->at(0)->true_branch_succs_Ctrl;
                } else {
                    // search for the loop_mux in its false succs
                    auto pos_ = std::find(loop_mux_preds->at(0)->false_branch_succs_Ctrl->begin(), loop_mux_preds->at(0)->false_branch_succs_Ctrl->end(), loop_mux);
                    assert(pos_ != loop_mux_preds->at(0)->false_branch_succs_Ctrl->end()); // it must be in the false succ
                    loop_mux_outside_pred_succs = loop_mux_preds->at(0)->false_branch_succs_Ctrl;
                }
            } else {
                loop_mux_outside_pred_succs = loop_mux_outside_pred->JustCntrlSuccs;
            }

        } else {
            if(loop_mux_preds->at(0)->type == Branch_c) {
                // search for the loop_mux in its true succs
                auto pos_ = std::find(loop_mux_preds->at(0)->true_branch_succs_Ctrl_lsq->begin(), loop_mux_preds->at(0)->true_branch_succs_Ctrl_lsq->end(), loop_mux);
                if(pos_ != loop_mux_preds->at(0)->true_branch_succs_Ctrl_lsq->end()) {
                    loop_mux_outside_pred_succs = loop_mux_preds->at(0)->true_branch_succs_Ctrl_lsq;
                } else {
                    // search for the loop_mux in its false succs
                    auto pos_ = std::find(loop_mux_preds->at(0)->false_branch_succs_Ctrl_lsq->begin(), loop_mux_preds->at(0)->false_branch_succs_Ctrl_lsq->end(), loop_mux);
                    assert(pos_ != loop_mux_preds->at(0)->false_branch_succs_Ctrl_lsq->end()); // it must be in the false succ
                    loop_mux_outside_pred_succs = loop_mux_preds->at(0)->false_branch_succs_Ctrl_lsq;
                }
            } else {
                loop_mux_outside_pred_succs = loop_mux_outside_pred->CntrlOrderSuccs;
            }
        }
    }   

    // search for the loop_mux in the succs of this pred
    auto pos_ = std::find(loop_mux_outside_pred_succs->begin(), loop_mux_outside_pred_succs->end(), loop_mux);
    assert(pos_ != loop_mux_outside_pred_succs->end());
    int idx_ = pos_ - loop_mux_outside_pred_succs->begin();
    loop_mux_outside_pred_succs->at(idx_) = supp;

    // and this should overwrite the data feeding the Branch
    assert(supp_preds->at(0) == loop_mux);
    supp_preds->at(0) = loop_mux_outside_pred;

    // the supp now should be seen to be outside of the loop so change its BB field to the BB of the preds that is coming from outside
    supp->BB = loop_mux_outside_pred->BB;

    // supp should now be the node feeding the loop_mux input from outside of the loop
    if(network_flag == data) {
        loop_mux_preds->at(1) = supp;
    } else {
        loop_mux_preds->at(0) = supp;
    }

    supp_succs->clear();
    supp_succs->push_back(loop_mux);

     // 4th ADjust the conditions and add TMFO!!! Do not forget to adhere with the convention of the TMFO!!
        // the condition of the SUPPRESS is in its Cntrlpreds.at(1) if it's Branch_n or .at(0) if Branch_c and the condition of the LoopMux is in CntrlPreds.at(0)
    ENode* tmfo = new ENode(TMFO, "tmfo");   // the TMFO is not inside any BB so I leave the BB field empty
    tmfo->id = tmfo_id++;

    // tmfo has 2 inputs (in0: cond of SUPP, in1: cond of REGEN) and 2 outputs (out0: to SUPP and out1: to REGEN(TAKE CARE: this means both to the loopMux and the Branch that feeds it!!!))
        // they are all conditional inputs of 1 bit so should be connected over the data network!!
    if(network_flag == data) {
        assert(supp->type == Branch_n);
        // in0 of tmfo is the condition of supp
        tmfo->CntrlPreds->push_back(supp->CntrlPreds->at(1));  // pushing the condition of the Supp

        // search for the supp in the succs of the supp->CntrlPreds->at(1)
        auto pos_ = std::find(supp->CntrlPreds->at(1)->CntrlSuccs->begin(), supp->CntrlPreds->at(1)->CntrlSuccs->end(), supp);
        assert(pos_ != supp->CntrlPreds->at(1)->CntrlSuccs->end());
        int idx_ = pos_ - supp->CntrlPreds->at(1)->CntrlSuccs->begin();
        supp->CntrlPreds->at(1)->CntrlSuccs->at(idx_) = tmfo;  // this should cut the connection between the supp and its condition and replace it with tmfo

        // update the condition of the SUPP to be fed from tmfo
        supp->CntrlPreds->at(1) = tmfo;
    } else {
        assert(supp->type == Branch_c);
        // in0 of tmfo is the condition of supp
        tmfo->CntrlPreds->push_back(supp->CntrlPreds->at(0));

        // search for the supp in the succs of the supp->CntrlPreds->at(1)
        auto pos_ = std::find(supp->CntrlPreds->at(0)->CntrlSuccs->begin(), supp->CntrlPreds->at(0)->CntrlSuccs->end(), supp);
        assert(pos_ != supp->CntrlPreds->at(0)->CntrlSuccs->end());
        int idx_ = pos_ - supp->CntrlPreds->at(0)->CntrlSuccs->begin();
        supp->CntrlPreds->at(0)->CntrlSuccs->at(idx_) = tmfo;

        // update the condition of the SUPP to be fed from tmfo
        supp->CntrlPreds->at(0) = tmfo;
    }
    // in1 of tmfo is the condition of regenerate
    tmfo->CntrlPreds->push_back(loop_mux->CntrlPreds->at(0));  // the condition of the LoopMux is always in .at(0) of the data network
    // search for the loop_mux in the Succs of its condition and replace it with tmfo
    auto pos__ = std::find(loop_mux->CntrlPreds->at(0)->CntrlSuccs->begin(), loop_mux->CntrlPreds->at(0)->CntrlSuccs->end(), loop_mux);
    assert(pos__ != loop_mux->CntrlPreds->at(0)->CntrlSuccs->end());
    int idx__ = pos__ - loop_mux->CntrlPreds->at(0)->CntrlSuccs->begin();
    loop_mux->CntrlPreds->at(0)->CntrlSuccs->at(idx__) = tmfo;

    // update the condition of the LoopMux of Regen to be fed from tmfo
    loop_mux->CntrlPreds->at(0) = tmfo;

    tmfo->tmfo_supp_succs = new std::vector<ENode*>;
    tmfo->tmfo_regen_succs = new std::vector<ENode*>;
    // update the condition of the Branch of Regen to be fed from tmfo
    if(network_flag == data) {
        assert(loop_mux->CntrlPreds->at(2)->type == Branch_n);  
       
        // search for the Regen Branch in the Succs of its condition to erase it from there.. (i.e., it is now an extra connection because that same condition is now already connected to the TMFO in replacement of the LoopMux condition)
        auto pos___ = std::find(loop_mux->CntrlPreds->at(2)->CntrlPreds->at(1)->CntrlSuccs->begin(), loop_mux->CntrlPreds->at(2)->CntrlPreds->at(1)->CntrlSuccs->end(), loop_mux->CntrlPreds->at(2));
        assert(pos___ != loop_mux->CntrlPreds->at(2)->CntrlPreds->at(1)->CntrlSuccs->end());
        loop_mux->CntrlPreds->at(2)->CntrlPreds->at(1)->CntrlSuccs->erase(pos___);

        loop_mux->CntrlPreds->at(2)->CntrlPreds->at(1) = tmfo;  // the condition of the Regen Branch should be tmfo

        // out1 of tmfo should feed the Branch of Regen
        tmfo->tmfo_regen_succs->push_back(loop_mux->CntrlPreds->at(2));
    } else {
        assert(loop_mux->JustCntrlPreds->at(1)->type == Branch_c);  
       
        // search for the Regen Branch in the Succs of its condition to erase it from there.. (i.e., it is now an extra connection because that same condition is now already connected to the TMFO in replacement of the LoopMux condition)
        auto pos___ = std::find(loop_mux->JustCntrlPreds->at(1)->CntrlPreds->at(0)->CntrlSuccs->begin(), loop_mux->JustCntrlPreds->at(1)->CntrlPreds->at(0)->CntrlSuccs->end(), loop_mux->JustCntrlPreds->at(1));
        assert(pos___ != loop_mux->JustCntrlPreds->at(1)->CntrlPreds->at(0)->CntrlSuccs->end());
        loop_mux->JustCntrlPreds->at(1)->CntrlPreds->at(0)->CntrlSuccs->erase(pos___);

        loop_mux->JustCntrlPreds->at(1)->CntrlPreds->at(0) = tmfo;  // the condition of the Regen Branch should be tmfo

        // out1 of tmfo should feed the Branch of Regen
        tmfo->tmfo_regen_succs->push_back(loop_mux->JustCntrlPreds->at(1));
    }

    // out0 should feed supp
    tmfo->tmfo_supp_succs->push_back(supp);
    // out1 should feed the LoopMux of Regen
    tmfo->tmfo_regen_succs->push_back(loop_mux);

    // WHILE THINKING OF THE BELOW POINT, THINK IF I EVER NEED TO NEGATE ANY OF THE INPUTS OF THE TMFO (I think I don't need to because the inputs of the original LoopMux and SUPP are already having their proper signs and the TMFO just bypasses the conditions)
    // TODOOO: DO not forget to adjust the conventions of your VHDL module of TMFO to not expect an inverter to be placed at the in0 and out0 of the TMFO!!
}


// This function is supposed to be called after addSuppress and after convert_to_special_mux but before addFork
/*void CircuitGenerator::OLDconvert_REGEN_SUPP(){
    ENode* loop_mux = nullptr;
    std::vector<ENode*>* loop_mux_succs = nullptr;
    std::vector<ENode*>* loop_mux_preds = nullptr;
    ENode* cons_branch = nullptr;
    bool found_cons_branch = false;
    int cons_branch_idx = -1;

    networkType cons_branch_network;

    for(auto& enode: *enode_dag) {
        found_cons_branch = false;
        cons_branch = nullptr;
        loop_mux = nullptr;
        cons_branch_idx = -1;
        if((enode->type == Loop_Phi_n || enode->type == Loop_Phi_c) && enode->is_regen_mux) {
            loop_mux = enode;

            // identify the succs and preds array of the loop_mux enode
            if(enode->type == Loop_Phi_n) {
                assert(enode->CntrlSuccs->size() > 0 && enode->CntrlPreds->size() > 0);
                loop_mux_succs = enode->CntrlSuccs;
                loop_mux_preds = enode->CntrlPreds;
            } else {
                if(enode->JustCntrlSuccs->size() > 0) {
                    assert(enode->JustCntrlPreds->size() > 0);
                    assert(enode->CntrlOrderSuccs->size() == 0 && enode->CntrlOrderPreds->size() == 0);
                    loop_mux_succs = enode->JustCntrlSuccs;
                    loop_mux_preds = enode->JustCntrlPreds;
                } else {
                    assert(enode->CntrlOrderSuccs->size() > 0 && enode->CntrlOrderPreds->size() > 0);
                    loop_mux_succs = enode->CntrlOrderSuccs;
                    loop_mux_preds = enode->CntrlOrderPreds;
                }
            }
            assert(loop_mux_succs != nullptr);
            assert(loop_mux_preds != nullptr);

            // loop over the succs of the enode
            for(int i = 0; i < loop_mux_succs->size(); i++) {
                ENode* succ = loop_mux_succs->at(i);
                if(succ->type == Branch_n || succ->type == Branch_c) {
                    auto pos_1 = std::find(succ->true_branch_succs->begin(), succ->true_branch_succs->end(), loop_mux);
                    auto pos_2 = std::find(succ->true_branch_succs_Ctrl->begin(), succ->true_branch_succs_Ctrl->end(), loop_mux);
                    auto pos_3 = std::find(succ->true_branch_succs_Ctrl_lsq->begin(), succ->true_branch_succs_Ctrl_lsq->end(), loop_mux);
                    // if the branch is not feeding the loop_mux enode (i.e., if it is not the Branch that is part of the regeneration)
                    if(pos_1 == succ->true_branch_succs->end() && pos_2 == succ->true_branch_succs_Ctrl->end() && pos_3 == succ->true_branch_succs_Ctrl_lsq->end()) {
                        cons_branch = succ;
                        found_cons_branch = true;
                        cons_branch_idx = i;
                        break;
                    }
                }
            }

            if(found_cons_branch) {
                std::vector<ENode*>* cons_branch_succs = nullptr;
                assert(cons_branch != nullptr && cons_branch_idx != -1);
                // add here the logic of exchanging the positions of the cons_branch and loop_mux and feed them with a TMFO component..

                // IMP to note: I assume here that Branches are all SUPPRESSes meaning that they have succs either in the true array or the false array but never both
                // 1st identify the type of the Branch to identify its array of succs
                if(cons_branch->type == Branch_n) {
                    assert(cons_branch->true_branch_succs_Ctrl->size() + cons_branch->true_branch_succs_Ctrl_lsq->size() + cons_branch->false_branch_succs_Ctrl->size() + cons_branch->false_branch_succs_Ctrl_lsq->size() == 0);
                    // identify the array of succs
                    if(cons_branch->true_branch_succs->size() > 0) {
                        assert(cons_branch->false_branch_succs->size() == 0);
                        cons_branch_succs = cons_branch->true_branch_succs;
                    } else {
                        assert(cons_branch->false_branch_succs->size() > 0);
                        cons_branch_succs = cons_branch->false_branch_succs;
                    }
                    cons_branch_network = data;
                } else {
                    assert(cons_branch->type == Branch_c);
                    assert(cons_branch->true_branch_succs->size() + cons_branch->false_branch_succs->size() == 0);
                    // identify the array of succs
                    if(cons_branch->true_branch_succs_Ctrl->size() > 0) {
                        assert(cons_branch->false_branch_succs_Ctrl->size() + cons_branch->true_branch_succs_Ctrl_lsq->size() + cons_branch->false_branch_succs_Ctrl_lsq->size() == 0);
                        cons_branch_succs = cons_branch->true_branch_succs_Ctrl;
                        cons_branch_network = constCntrl;
                    } else {
                        if(cons_branch->false_branch_succs_Ctrl->size() > 0){
                            assert(cons_branch->true_branch_succs_Ctrl_lsq->size() + cons_branch->false_branch_succs_Ctrl_lsq->size() == 0);
                            cons_branch_succs = cons_branch->false_branch_succs_Ctrl;
                            cons_branch_network = constCntrl;
                        } else {
                            if(cons_branch->true_branch_succs_Ctrl_lsq->size() > 0){
                                assert(cons_branch->false_branch_succs_Ctrl_lsq->size() == 0);
                                cons_branch_succs = cons_branch->true_branch_succs_Ctrl_lsq;
                            } else {
                                assert(cons_branch->false_branch_succs_Ctrl_lsq->size() > 0);
                                cons_branch_succs = cons_branch->false_branch_succs_Ctrl_lsq;
                            }
                            cons_branch_network = memDeps;
                        }
                    }
                }
                assert(cons_branch_succs != nullptr);

                // 2nd loop over the succs of the Branch and add them all to the succs of the enode such that the very first succ is put in place of the Branch
                loop_mux_succs->at(cons_branch_idx) = cons_branch_succs->at(0);
                for(int i = 1; i < cons_branch_succs->size(); i++) {
                    loop_mux_succs->push_back(cons_branch_succs->at(i));
                }
                // let the loop_mux enode replace the cons_branch in the preds of each succ of cons_branch!!
                for(int i = 0; i < cons_branch_succs->size(); i++) {
                    switch(cons_branch_network) {
                      case data:
                      {
                        auto pos__1 = std::find(cons_branch_succs->at(i)->CntrlPreds->begin(), cons_branch_succs->at(i)->CntrlPreds->end(), cons_branch);
                        assert(pos__1 != cons_branch_succs->at(i)->CntrlPreds->end());
                        int idx__1 = pos__1 - cons_branch_succs->at(i)->CntrlPreds->begin();
                        cons_branch_succs->at(i)->CntrlPreds->at(idx__1) = loop_mux;
                        break;
                      }
                        
                      case constCntrl:
                      {
                        auto pos__2 = std::find(cons_branch_succs->at(i)->JustCntrlPreds->begin(), cons_branch_succs->at(i)->JustCntrlPreds->end(), cons_branch);
                        assert(pos__2 != cons_branch_succs->at(i)->JustCntrlPreds->end());
                        int idx__2 = pos__2 - cons_branch_succs->at(i)->JustCntrlPreds->begin();
                        cons_branch_succs->at(i)->JustCntrlPreds->at(idx__2) = loop_mux;
                        break;
                      }
                        
                      case memDeps:
                      {
                        auto pos__3 = std::find(cons_branch_succs->at(i)->CntrlOrderPreds->begin(), cons_branch_succs->at(i)->CntrlOrderPreds->end(), cons_branch);
                        assert(pos__3 != cons_branch_succs->at(i)->CntrlOrderPreds->end());
                        int idx__3 = pos__3 - cons_branch_succs->at(i)->CntrlOrderPreds->begin();
                        cons_branch_succs->at(i)->CntrlOrderPreds->at(idx__3) = loop_mux;
                        break;
                      }
                        
                    }
                }


                // 3rd the cons_branch should be placed between the loop_mux and its pred that comes from outside of the loop 
                    // and the cons_branch should have the loop_mux as its only succ
                // identify the loop_mux pred that comes from outside the loop

                // making sure that in0 comes from outside
                if(loop_mux_preds == loop_mux->CntrlPreds) {
                    assert(!BBMap->at(loop_mux->BB)->loop->contains(loop_mux_preds->at(1)->BB));  // (i.e., in0 of the Mux should come from outside the loop)
                    assert(loop_mux_preds->at(1)->type != Branch_n && loop_mux_preds->at(1)->type != Branch_c);   // TEMPORARY ASSUMING THAT IT CAN NOT BE A BRANCH TO AVOID CHECKING THE SUCC ARRAYS OF A BRANCH...
                    
                    // search for the loop_mux in the CntrlSuccs of this pred
                    auto pos_ = std::find(loop_mux_preds->at(1)->CntrlSuccs->begin(), loop_mux_preds->at(1)->CntrlSuccs->end(), loop_mux);
                    assert(pos_ != loop_mux_preds->at(1)->CntrlSuccs->end());
                    int idx_ = pos_ - loop_mux_preds->at(1)->CntrlSuccs->begin();
                    loop_mux_preds->at(1)->CntrlSuccs->at(idx_) = cons_branch;

                    // and this should overwrite the data feeding the Branch
                    assert(cons_branch->CntrlPreds->at(0) == loop_mux);
                    cons_branch->CntrlPreds->at(0) = loop_mux_preds->at(1);

                    // the cons_branch now should be seen to be outside of the loop so change its BB field to the BB of the preds that is coming from outside
                    cons_branch->BB = loop_mux_preds->at(1)->BB;

                    // cons_branch should now be the node feeding the loop_mux input from outside the loop
                    loop_mux_preds->at(1) = cons_branch;

                } else {
                    assert(!BBMap->at(loop_mux->BB)->loop->contains(loop_mux_preds->at(0)->BB));  
                    assert(loop_mux_preds->at(0)->type != Branch_n && loop_mux_preds->at(0)->type != Branch_c);   // TEMPORARY ASSUMING THAT IT CAN NOT BE A BRANCH TO AVOID CHECKING THE SUCC ARRAYS OF A BRANCH...

                    // the cons_branch now should be seen to be outside of the loop so change its BB field to the BB of the preds that is coming from outside
                    cons_branch->BB = loop_mux_preds->at(0)->BB;

                    // cons_branch should now be the node feeding the loop_mux input from outside the loop
                    loop_mux_preds->at(0) = cons_branch;

                    if(loop_mux_preds == loop_mux->JustCntrlPreds) {
                         // search for the loop_mux in the JustCntrlSuccs
                        auto pos_ = std::find(loop_mux_preds->at(0)->JustCntrlSuccs->begin(), loop_mux_preds->at(0)->JustCntrlSuccs->end(), loop_mux);
                        assert(pos_ != loop_mux_preds->at(0)->JustCntrlSuccs->end());
                        int idx_ = pos_ - loop_mux_preds->at(0)->JustCntrlSuccs->begin();
                        loop_mux_preds->at(0)->JustCntrlSuccs->at(idx_) = cons_branch;

                        // and this should overwrite the data feeding the Branch
                        assert(cons_branch->JustCntrlPreds->at(0) == loop_mux);
                        cons_branch->JustCntrlPreds->at(0) = loop_mux_preds->at(0);
                    } else {
                        assert(loop_mux_preds == loop_mux->CntrlOrderPreds);
                        // search for the loop_mux in the JustCntrlSuccs
                        auto pos_ = std::find(loop_mux_preds->at(0)->CntrlOrderSuccs->begin(), loop_mux_preds->at(0)->CntrlOrderSuccs->end(), loop_mux);
                        assert(pos_ != loop_mux_preds->at(0)->CntrlOrderSuccs->end());
                        int idx_ = pos_ - loop_mux_preds->at(0)->CntrlOrderSuccs->begin();
                        loop_mux_preds->at(0)->CntrlOrderSuccs->at(idx_) = cons_branch;

                        // and this should overwrite the data feeding the Branch
                        assert(cons_branch->CntrlOrderPreds->at(0) == loop_mux);
                        cons_branch->CntrlOrderPreds->at(0) = loop_mux_preds->at(0);
                    }
                }
                // the only succs of the cons_branch now should be the loop_mux and it should be in0 of the loop_mux preds
                cons_branch_succs->clear();
                cons_branch_succs->push_back(loop_mux);

                // 4th ADjust the conditions and add TMFO!!! Do not forget to adhere with the convention of the TMFO!!
                // the condition of the SUPPRESS is in its Cntrlpreds.at(1) if it's Branch_n or .at(0) if Branch_c and the condition of the LoopMux is in CntrlPreds.at(0)
                // SHould simply add a TMFO object feeding both conditions (out0 for SUPP and out1 for LoopMux) and have the old conditions inputs to the LoopMux

                // BUT FOR NOW, LET'S TEST JUST THE FACT THAT THE MUX AND THE BRANCH ARE CORRECTLY SWAPPED!!!


            }  // end of the if condition that checks if found_cons_branch...

        }
    }
}*/