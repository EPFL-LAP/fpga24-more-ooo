/**
 * Elastic Pass
 *
 * Forming a netlist of dataflow components out of the LLVM IR
 *
 */

#include <cassert>

#include "llvm/ADT/Statistic.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/RandomNumberGenerator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "ElasticPass/CircuitGenerator.h"
#include "ElasticPass/Utils.h"
#include "ElasticPass/Head.h"
#include "ElasticPass/Nodes.h"
#include "ElasticPass/Pragmas.h"
#include "OptimizeBitwidth/OptimizeBitwidth.h"


#include <sys/time.h>
#include <time.h>

static cl::opt<bool> opt_useLSQ("use-lsq", cl::desc("Emit LSQs where applicable"), cl::Hidden,
                                cl::init(true), cl::Optional);

static cl::opt<std::string> opt_cfgOutdir("cfg-outdir", cl::desc("Output directory of MyCFGPass"),
                                          cl::Hidden, cl::init("."), cl::Optional);

static cl::opt<bool> opt_buffers("simple-buffers", cl::desc("Naive buffer placement"), cl::Hidden,
                                cl::init(false), cl::Optional);

static cl::opt<std::string> opt_serialNumber("target", cl::desc("Targeted FPGA"), cl::Hidden,
                                cl::init("default"), cl::Optional);

struct timeval start, time_end;

std::string fname;
static int indx_fname = 0;

void set_clock() { gettimeofday(&start, NULL); }

double elapsed_time() {
    gettimeofday(&time_end, NULL);

    double elapsed = (time_end.tv_sec - start.tv_sec);
    elapsed += (double)(time_end.tv_usec - start.tv_usec) / 1000000.0;
    return elapsed;
}

using namespace llvm;

//class ControlDependencyGraph;

namespace {
class MyCFGPass : public llvm::FunctionPass {

public:
    static char ID;

    MyCFGPass() : llvm::FunctionPass(ID) {}

    virtual void getAnalysisUsage(AnalysisUsage& AU) const {
        // 			  AU.setPreservesCFG();
        AU.addRequired<OptimizeBitwidth>();
		OptimizeBitwidth::setEnabled(false);  // pass true to it to enable OB	

        AU.addRequired<MemElemInfoPass>();

		AU.addRequired<LoopInfoWrapperPass>();

    }

    void compileAndProduceDOTFile(Function& F , LoopInfo& LI) {
        fname = F.getName().str();

        // main is used for frequency extraction, we do not use its dataflow graph
        if (fname != "main") {

            bool done = false;

            auto M = F.getParent();

            pragmas(0, M->getModuleIdentifier());

            std::vector<BBNode*>* bbnode_dag = new std::vector<BBNode*>;
            std::vector<ENode*>* enode_dag   = new std::vector<ENode*>;
            OptimizeBitwidth* OB             = &getAnalysis<OptimizeBitwidth>();
            MemElemInfo& MEI                 = getAnalysis<MemElemInfoPass>().getInfo();

            //----- Internally constructs elastic circuit and adds elastic components -----//

            // Naively building circuit
            CircuitGenerator* circuitGen = new CircuitGenerator(enode_dag, bbnode_dag, OB, MEI);//, CDGP);//, CDG);



	    // calling functions implemented in `AddComp.cpp`
            circuitGen->buildDagEnodes(F);
            circuitGen->fixBuildDagEnodes();
            circuitGen->removeRedundantBeforeElastic(bbnode_dag, enode_dag);
            circuitGen->setGetelementPtrConsts(enode_dag);

#if 1
			circuitGen->buildPostDomTree(F);
			circuitGen->constructDomTree(F);


			// AYA: 01/10/2021
			circuitGen->Fix_LLVM_PhiPreds();

			// AYA: 21/10/2022: temporarily calling this function here to trigger all constants from source
			//circuitGen->addSourceForConstants();   

	    	circuitGen->addStartC();


	    	// AYA: 07/12/2022: temporarily placing this here!!
	        printDotCFG(bbnode_dag, (opt_cfgOutdir + "/" + fname + "_bbgraph.dot").c_str());


	    	// Aya: 12/09/2022: Added a flag to choose a mode of operation for the CntrlOrder network for interfacing with the LSQ:
			/*
				- If false: Make the CntrlOrder network strictly follow the sequential control flow,
				Or - If True: Make the CntrlOrder network implement the FPGA'23 algorithm
			*/
			// depending on the experiment I want, I manually change the flag to true or false.
			bool is_smart_cntrlOrder_flag = true;

			bool lazy_fork_flag = false;

			circuitGen->printDebugDominatorTree();

			
			if(!is_smart_cntrlOrder_flag) {
				circuitGen->buildRedunCntrlNet();  
			}


			// 12/09/2022: moved this function call to happen earlier because I need to check the conditions of execution inside the addMemoryInterfaces function!!
			circuitGen->identifyBBsForwardControlDependency();

			circuitGen->FindLoopDetails(LI);

			// std::ofstream general_dbg_file;
			// general_dbg_file.open("general_MYCFG_dbg.txt");

			// general_dbg_file << "\n HIIII before addMemoryInterfaces\n";


			// This function (implemented in Memory.cpp) takes care of all the memory stuff; mainly operates on the CntrlOrder network
			// Aya: 12/09/2022 added an extra parameter to tell the function if we will interface with thr LSQ the conservative or the smart way!
			circuitGen->addMemoryInterfaces(opt_useLSQ, is_smart_cntrlOrder_flag, lazy_fork_flag);
			//general_dbg_file << "\nAfter addMemoryInterfaces\n";



			/////////////////////////////////////////// TEMPORARILY FOR DEBUGGING!!!
			/*std::ofstream dbg_file_15;
    		dbg_file_15.open("check_CntrlOrderNetwork.txt");
			for(auto& enode: *enode_dag) {
				if(enode->CntrlOrderPreds->size() > 0) {
					dbg_file_15 << "\n\nNew node of type: " << getNodeDotTypeNew(enode);
					if(enode->BB != nullptr)
						dbg_file_15 << " and BB" << circuitGen->BBMap->at(enode->BB)->Idx  + 1 << " has the following preds in the CntrlOrderPreds\n";
					else 
						dbg_file_15 << " and BB_NULL " << " has the following preds in the CntrlOrderPreds\n";
						
				}
				// loop over the control order network to check its predecessors and successors
				for(auto& pred: *enode->CntrlOrderPreds) {
					if(pred->BB != nullptr)
						dbg_file_15 << getNodeDotTypeNew(pred) << " in BB" << circuitGen->BBMap->at(pred->BB)->Idx  + 1 << ", ";
					else
						dbg_file_15 << getNodeDotTypeNew(pred) << " in BB_NULL, ";
				}
				dbg_file_15 << "\n\n";
			}*/
			///////////////////////////////////////////////////////////////////////////////

			/* Aya: 23/05/2022: Applying FPL's algorithm
			 */
					
			//circuitGen->printCDFG();

			// std::ofstream dbg_file_5;
    		// dbg_file_5.open("check_final_loops_details.txt");
			// circuitGen->debugLoopsOutputs(dbg_file_5);
			// dbg_file_5.close();

			// AYA: 08/10/2022: added the following to trigger the return of void functions
			circuitGen->connectReturnToVoid_irredundant();


			// the following function is responsible for adding Merges for re-generation!
			circuitGen->checkLoops(F, LI, CircuitGenerator::data);
			circuitGen->checkLoops(F, LI, CircuitGenerator::constCntrl);

			if(is_smart_cntrlOrder_flag) {
				// 10/08/2022: added the following copy of checkLoops to operate on the CntrlOrder network
				circuitGen->checkLoops(F, LI, CircuitGenerator::memDeps);
			}

				// MY GOAL is to have a single PHI of my insertion ONLY in the innermost loop that the consumer is inside and the producer is not inside
					// SINCE IT IS STILL EXPERIMENTAL AND IN ORDER TO NOT MESS UP WITH OTHER STUFF, I WILL NOT CHANGE ANYTHING IN THE ABOVE FUNCTION OF INSERTING PHIS AND WILL DO THE CHANGES I WANT IN A NEW FUNCTION THAT DELETES THE EXTRA ADDED STUFF
			
			// To ttest these functions, 1) uncomment the following 3 lines, 2) Need to do a change in the body of "if(producer == consumer)", Currently the code that works for regenerate is put in the else of "if(network_flag == constCntrl || network_flag == memDeps || network_flag == data) {"
			//circuitGen->TEMP_deleteExtraPhis(CircuitGenerator::data);
			//circuitGen->TEMP_deleteExtraPhis(CircuitGenerator::constCntrl);
			//circuitGen->TEMP_deleteExtraPhis(CircuitGenerator::memDeps);

			//general_dbg_file << "\nAfter the 3 calls of checkLoops!\n";

			
			//////// TEMPORARILY FOR DEBUGGING!!
			// std::ofstream dbg_file;
    		// dbg_file.open("PROD_CONS_BBs.txt");

			// for (auto& enode : *enode_dag) {
			// 	for (auto& succ : *enode->CntrlSuccs) {
			// 		dbg_file << "\n---------------------------------------------------\n";
			// 		if(enode->BB!=nullptr && succ->BB!=nullptr)
			// 			dbg_file << "Producer in BB" << aya_getNodeDotbbID(circuitGen->BBMap->at(enode->BB)) << " to a Consumer in BB " << aya_getNodeDotbbID(circuitGen->BBMap->at(succ->BB)) << "\n";
			// 	}
			// }
			
			circuitGen->removeExtraPhisWrapper(CircuitGenerator::data);
			circuitGen->removeExtraPhisWrapper(CircuitGenerator::constCntrl);
			if(is_smart_cntrlOrder_flag) {
				circuitGen->removeExtraPhisWrapper(CircuitGenerator::memDeps);
			}
			
			//general_dbg_file << "\nAfter the 3 calls of removeExtraPhisWrapper!\n";


			// AYA: 06/10/2021: added this to make sure the predecessors of any Phi we added above is compatible with the order of the LLVM convention to be able to convert them to muxes later!
			circuitGen->Fix_my_PhiPreds(LI, CircuitGenerator::data);  // to fix my phi_
			circuitGen->Fix_my_PhiPreds(LI, CircuitGenerator::constCntrl);  // to fix my irredundant phi_c

			if(is_smart_cntrlOrder_flag) {
				circuitGen->Fix_my_PhiPreds(LI, CircuitGenerator::memDeps);
			}

			//general_dbg_file << "\nAfter the 3 calls of Fix_my_PhiPreds!\n";

			/////////////////////////////////////////////////

			circuitGen->addSuppress_with_loops(CircuitGenerator::data); // connect producers and consumers of the datapath
			circuitGen->addSuppress_with_loops(CircuitGenerator::constCntrl);  // trigger constants from START through the data-less network

			if(is_smart_cntrlOrder_flag) {
				circuitGen->addSuppress_with_loops(CircuitGenerator::memDeps);
			}

			// AYA: 25/07/2023: the goal of the following new function is to tweak the condition of some Branches that are placed after more prod than cons
			/*circuitGen->fixSuppress_more_prod_than_cons_wrapper(CircuitGenerator::data);
			circuitGen->fixSuppress_more_prod_than_cons_wrapper(CircuitGenerator::constCntrl); // it is probably never needed for this network, but I'm dong it just in case..
			if(is_smart_cntrlOrder_flag) {
				circuitGen->fixSuppress_more_prod_than_cons_wrapper(CircuitGenerator::memDeps);
			}*/

			//general_dbg_file << "\nAfter the 3 calls of addSuppress_with_loops!\n";

			// AYA: 26/03/2023: commenting out the SUPPRESS to Branches optimizations to make the term rewriting system work!!!!!
			circuitGen->removeExtraBranchesWrapper(CircuitGenerator::data);
			circuitGen->removeExtraBranchesWrapper(CircuitGenerator::constCntrl);
			if(is_smart_cntrlOrder_flag) {
				circuitGen->removeExtraBranchesWrapper(CircuitGenerator::memDeps);
			}
			
			//general_dbg_file << "\nAfter the 3 calls of removeExtraBranchesWrapper!\n";

			// AYA: 24/04/2023: TODO: Note that the following setMuxes_nonLoop() function crashes when a BB in the CFG is fed by three inputs

			// Aya: 16/06/2022: final version of setMuxes that converts only the Merges at the confluence points not at the loop headers into MUXes
				// this is why internally it does not need to operate on Phi_c because those are never inserted except at loop headers (for regeneration)
			circuitGen->setMuxes_nonLoop(); 
			//general_dbg_file << "\nAfter setMuxes_nonLoop!\n";


			//circuitGen->deleteLLVM_Br();  // AYA: 20/07/2023: removed this to happen later in the end after the functions for fixing ST and MC!!
			//general_dbg_file << "\nAfter deleteLLVM_Br!\n";


			// AYA: 15/11/2021: Trigger all constants (except those triggering an unconditional branch) through a Source component in the same BB
			//circuitGen->addSourceForConstants();

			//////// TEMPORARILY FOR DEBUGGING!!
			// std::ofstream dbg_file_8;
    		// dbg_file_8.open("check_Pred_succs_of_gsa_non_loop_mux.txt");
    		// for (auto& enode : *enode_dag) {
    		// 	if(enode->is_non_loop_gsa_mux) {
			// 		assert(enode->type == Phi_c);
			// 		dbg_file_8 << "\n\nFound 1 non_loop_gsa_mux with " << enode->CntrlOrderPreds->size() << " CntrlOrderPreds, " <<  enode->JustCntrlPreds->size() << " JustCntrlPreds, " << enode->CntrlOrderSuccs->size() << " CntrlOrderSuccs, "  << enode->JustCntrlSuccs->size() << " JustCntrlSuccs" << "\n";
			// 		if(enode->CntrlOrderSuccs->size() > 0) {
			// 			assert(enode->CntrlOrderSuccs->size() == 1);
			// 			dbg_file_8 << "\n\tThe enode->CntrlOrderSuccs->at(0) is of type " << enode->CntrlOrderSuccs->at(0)->type << "\n";
			// 		}
			// 	}

			// }


			// Aya: 13/09/2022: added the following function (implemented in Memory.cpp) to optimize the Bx components that are having no succs thus fed to a sink!!
	      	if(is_smart_cntrlOrder_flag)
	      		circuitGen->removeUselessBxs(lazy_fork_flag);

			//general_dbg_file << "\nAfter removeUselessBxs!\n";


	      	// dbg_file_8 << "\nAfter calling removeUselessBxs!\n ";
	      	// for (auto& enode : *enode_dag) {
    		// 	if(enode->is_non_loop_gsa_mux) {
			// 		assert(enode->type == Phi_c);
			// 		dbg_file_8 << "\n\nFound 1 non_loop_gsa_mux with " << enode->CntrlOrderPreds->size() << " CntrlOrderPreds, " <<  enode->JustCntrlPreds->size() << " JustCntrlPreds, " << enode->CntrlOrderSuccs->size() << " CntrlOrderSuccs, "  << enode->JustCntrlSuccs->size() << " JustCntrlSuccs" << "\n";
			// 		if(enode->CntrlOrderSuccs->size() > 0) {
			// 			assert(enode->CntrlOrderSuccs->size() == 1);
			// 			dbg_file_8 << "\n\tThe enode->CntrlOrderSuccs->at(0) is of type " << enode->CntrlOrderSuccs->at(0)->type << "\n";

			// 			if(enode->CntrlOrderSuccs->at(0)->type == LSQ_) {
			// 				// search for the enode in the predecessors of the LSQ!!
			// 				auto pos_check = std::find(enode->CntrlOrderSuccs->at(0)->CntrlOrderPreds->begin(), enode->CntrlOrderSuccs->at(0)->CntrlOrderPreds->end(), enode);
			// 				assert(pos_check != enode->CntrlOrderSuccs->at(0)->CntrlOrderPreds->end());
			// 				dbg_file_8 << "\n\tThe index of the non_loop_gsa_mux in the CntrlOrderPreds of the LSQ is  " << pos_check - enode->CntrlOrderSuccs->at(0)->CntrlOrderPreds->begin() << "\n";
			// 			}
			// 		}
			// 	}

			// }

			// FOR THIS FLAG TO BE FALSE EFFECTIVELY, MAKE SURE 1) YOU ARE NOT RAISING THE TAG FLAG, 2) YOU HAVE ONLY 1 THREAD IN YOUR CODE
			bool loopMux_flag = false;
			if(loopMux_flag) {
				// 26/02/2023: The following functions is meant to modify the graphs to fit the new loop-related ideas
			// 1st remove all INITs with their constants
			// 2nd change the type of the MUX to map to the loop-mux in the backend
			// 3rd change the inputs order of the MUX is needed to comply with the convention that the 0th input should always come from outside
				circuitGen->convert_to_special_mux();

				// AYA: 29/04/2023: Forcing the insertion of a Synchronizer component that gets fed with all in0 of all LoopMUXes belonging to 1 loop
				circuitGen->synch_loopMux();
			}

			// AYA: 16/09/2023: TEMPORARILY: MAKE SURE TO TWEAK THE CODE TO CHOOSE THE RIGHT CMERGE BASED ON THE EXAMPLE!!
			// AYA: 16/09/2023: the purpose of this function is to convert one of the Muxes of every loop into a CMerge and let its condition output serve as the select of all other MUxes of this loop
			// TODO!! THEN, CHECK THAT YOU ACHIEVE THE BEST PERFORMANCE IN SIMULATION, THEN, TAGGER to limit the tokens in case we have more threards 
				// Then, collect results for some benchmarks!!
            std::string tag_info_path;
            get_tag_info_file_path(tag_info_path); 
            bool loop_cmerge_flag = is_tag_from_input(tag_info_path);
			bool ignore_outer_most_loop = true; //true;
			if(loop_cmerge_flag) {
				circuitGen->convert_loop_cmerge(tag_info_path, ignore_outer_most_loop);  // implemented in newLoops_management.cpp: needs to tweak the condition of picking the master Mux based on the example
																		// currenly applies the logic of finding the master Cmerge for every loop in the circuit 
			}
			// MOved the following block to happen afterwards because I would like to include any potential circuitry that could be added below in the inputs/outputs of TAGGER/UNTAGGER
			/*bool if_else_cmerge_flag = true;
			if(if_else_cmerge_flag) {
				circuitGen->convert_if_else_cmerge();
			}
			if(loop_cmerge_flag || if_else_cmerge_flag)
				circuitGen->insert_tagger_untagger_wrapper(); // implemented in AddTags.cpp: 
			*/


			// TODO: ADD A FUNCTION ABOVE TO STORE THE ORIGINAL PRODUCER AND CONSUMERS BEFORE ADDING ANY REGENERATES OR SUPPRESSES..
				// THE GOAL IS TO IDENTIFY PAIRS OF ORIGINAL PRODUCERS AND CONSUMER FROM THIS TO APPLY THE TERM REWRITING FOR EACH PAIR..
			// EXPERIMENTING converting REGEN_SUPP to SUPP_REGEN
			// 18/03/2023: added a function that converts a REGEN followed by a SUPP to a SUPP followed by a REGEN and uses the TMFO to do so..
			//circuitGen->apply_term_rewriting(CircuitGenerator::data);  // CAN VERIFY ON THE SIMPLEST EXAMPLE WITH ONE LOOP WITH A CONSUMER EXECUTING CONDITIONALLY!!!
			//circuitGen->apply_term_rewriting(CircuitGenerator::constCntrl); 
			//circuitGen->apply_term_rewriting(CircuitGenerator::memDeps); 

			// TEMPORARILY FOR DEBUGGING: 26/03/2023
			/*std::ofstream dbg_file_term_rewriting;
    		dbg_file_term_rewriting.open("term_rewriting_check.txt");
    		for(auto& enode : *enode_dag) {
    			if(enode->type == Loop_Phi_n && enode->is_regen_mux) {
    				dbg_file_term_rewriting << "\n" << getNodeDotNameNew(enode) << " has the following preds:\n\t ";
    				for(int i = 0; i < enode->CntrlPreds->size(); i++) {
    					dbg_file_term_rewriting << "Pred with index " << i << " with enode name called " << getNodeDotNameNew(enode->CntrlPreds->at(i)) << ", ";
    				}
    			}
    			dbg_file_term_rewriting << "\n";
    		}*/

			// AYA: 06/09/2023: Added the following function to make sure that the inputs of the INIT are "false" always at in0 and "true" at in1 except one "false" in the end to take us back to the initial state
			bool fix_init_inputs_flag = true;//loop_cmerge_flag;   // AYA: 29/11/2023: changed it to blindly follow the loop_cmerge_flag; otherwise, it will crash
			     // AYA: 04/12/2023: Remember that the above flag MUST be TRUE if you are using the cleaned up INIT that does not have a leftover token in elastic_components.vhd
                    // THis is the case for both the fast token delivery witb the cleaned up INIT or the multithreading tagging of FPGA'24
            if(fix_init_inputs_flag)
				circuitGen->fix_INIT_inputs();

			bool if_else_cmerge_flag = loop_cmerge_flag;
			if(if_else_cmerge_flag) {
				circuitGen->convert_if_else_cmerge(tag_info_path);
			}
			if(loop_cmerge_flag || if_else_cmerge_flag)
				circuitGen->insert_tagger_untagger_wrapper(); // implemented in AddTags.cpp: 


		// IMP Note: this function is also important to connect the predecessors of all branches!!!
			circuitGen->Aya_addFork();
			// AYA: 18/09/2023: tagging the newly added forks (and other components) if they are belonging to a tagged cluster!
			
			// AYA: 18/09/2023: call the following function to label the clustered nodes as tagged
			if(loop_cmerge_flag || if_else_cmerge_flag) {
				circuitGen->tag_cluster_nodes(); // implemented in AddTags.cpp: 

				// AYA: 28/09/2023
				circuitGen->addMissingAlignerInputs(tag_info_path);  // this function (i) inserts the ALIGNER, (ii) identifies the DIRTY nodes, marks them and passes their clean inputs through the TAGGER/UNTAGGER
			}

			//general_dbg_file << "\nAfter addFork!\n";

			// Aya: 05/11/2022: added the following function to make sure to transfer any fork feeding the LSQ to a LazyFork
				// this is needed only if we use the naive interface with the LSQ through the ordered network of control merges because in case of the smart network, the type of the fork is defined from the moment we insert it inside the Memory.cpp
			if(!is_smart_cntrlOrder_flag && lazy_fork_flag) {
				circuitGen->convert_LSQ_fork_to_lazy();  // implemented in Memory.cpp
			}

			// AYA: 03/08/2023: added the following function that loops over Branch_c nodes that still do not have their succs connected and adds them..
				// This is because due to weird LLVM errors, I had to comment this part from Aya_addFork() function, so I'm tryin to do it here
			circuitGen->extraCheck_AddBranchSuccs();

			// AYA: 27/11/2022: converting the merges in the ordered only control network to CMerges to check if it will matter with buffers
			/*if(!is_smart_cntrlOrder_flag) {
				circuitGen->convert_Merges_to_CMerges();
			}*/


			// TEMPORARILY FOR DEBUGGING!
			/*dbg_file_9 << "\n\tPrinting again after addFork!!\n\n";
			for (auto& enode : *enode_dag) {
				if(enode->is_non_loop_gsa_mux) {
					assert(enode->type == Phi_c);
					dbg_file_9 << "\n---------------------------------------------------\n";
					dbg_file_9 << "Found 1 non_loop_gsa_mux with " << enode->CntrlOrderPreds->size() << " CntrlOrderPreds\n";
					if(enode->JustCntrlPreds->size() == 0) {
						dbg_file_9 << "It has no JustCntrlPreds!!\n\n";
					} else {
						dbg_file_9 << "It has " << enode->JustCntrlPreds->size() << " JustCntrlPreds!!\n\n";
					}

					dbg_file_9 << " Printing the CntrlOrderPreds..\n";
					for (auto& pred : *enode->CntrlOrderPreds) {
						dbg_file_9 << "Node name is " << getNodeDotNameNew(pred) << "of type " << pred->type << " in BB" << circuitGen->BBMap->at(pred->BB)->Idx + 1 << ", ";
					}

					dbg_file_9 << "\nPrinting the index of the non_loop_gsa_mux in the 2nd predecessor: ";
					auto pos__ = std::find(enode->CntrlOrderPreds->at(1)->true_branch_succs_Ctrl_lsq->begin(), enode->CntrlOrderPreds->at(1)->true_branch_succs_Ctrl_lsq->end(), enode);
					if(pos__ != enode->CntrlOrderPreds->at(1)->true_branch_succs_Ctrl_lsq->end()) {
						int idx = pos__ - enode->CntrlOrderPreds->at(1)->true_branch_succs_Ctrl_lsq->begin();
						dbg_file_9 << " in true Succs " << idx << "\n";
					} else {
						auto pos_ = std::find(enode->CntrlOrderPreds->at(1)->false_branch_succs_Ctrl_lsq->begin(), enode->CntrlOrderPreds->at(1)->false_branch_succs_Ctrl_lsq->end(), enode);
						assert(pos_ != enode->CntrlOrderPreds->at(1)->false_branch_succs_Ctrl_lsq->end());
						int idx = pos__- enode->CntrlOrderPreds->at(1)->false_branch_succs_Ctrl_lsq->begin();
						dbg_file_9 << " in false Succs " << idx << "\n";

					}
				}
			}*/

			//circuitGen->remove_SUPP_COND_Negation();

			
	   // call a function to create the exit node, NEED TO CHECK RETURN LOGIC!!
	      	circuitGen->addExitC();
			//general_dbg_file << "\nAfter addExitC!\n";

	      	/* AYA: 12/07/2023:
		      	It is IMP to note that to make the new ST and MC designs work, you need to do the following steps:
			      	1) Make the fix_mc_st_interfaces_flag true and compile
			      	2) Make the same flag true in write_components() in vhdl_writer.cpp and compile
			      	3) Make sure you give the "mc_store_op" name to the correct VHDL module in MemCont.vhd (and same for the MemCont module itself)
	      	*/
	      	// THE FOLLOWING FLAGS NEED TO BE ASSOCIATED WITH A FLAG IN THE VHDL WRITER TO BE EFFECTIVE!!
			bool fix_mc_st_interfaces_flag = false;//false;
			bool fix_mc_st_interfaces_flag_yes_extra_ST_output = false;

			// AYA: 06/07/2023: A new function to cut the connection between any MC and END and replace it with
				// i) a new extra connection between ST and END, ii) a new extra connection between every ST and MC
			if(fix_mc_st_interfaces_flag) {
	      		circuitGen->fix_ST_MC_interfaces(fix_mc_st_interfaces_flag_yes_extra_ST_output);  // implemented in AddCtrl.cpp

	      		circuitGen->deliver_ACK_tokens_wrapper();  // this function adds the necessary steering components between any ST and END
	      						// In particular, it takes care of 1) compensating for a token if ST will not execute, 2) Discarding the extra ACKs if the ST is inside a loop
				//circuitGen->fixForks();

			}

			circuitGen->deleteLLVM_Br();
	      	
			if (opt_buffers)
				circuitGen->addBuffersSimple_OLD();

			//general_dbg_file << "\nAfter addBuffersSimple_OLD!\n";

	      	// THE FOLLOWING FLAGS NEED 1) TO BE ASSOCIATED WITH A FLAG IN THE VHDL WRITER TO BE EFFECTIVE!!, 2) NEEDS TO CHANGE THE VHDL OF LOOPMUX TO THE TAGGED
			// 05/08/2023
			bool tag_some_components_flag = false; //true;
			if(tag_some_components_flag){
				circuitGen->tag_some_components();
				//circuitGen->insert_loop_exit_robs();
			}

			// general_dbg_file.close();


	// Aya: The following is meant for optimizing bit width
       		if (OptimizeBitwidth::isEnabled()) {
				circuitGen->setSizes();   // called in Bitwidth.cpp
			}
	
	////////////////////////////////////////////////// DONEEE!

	// These were in the original Dynamatic, not sure if I need to fix and add them!!
		// circuitGen->removeRedundantAfterElastic(enode_dag);

	// this is important in filling the frequency field of BBs needed later in buffers
			circuitGen->setFreqs(F.getName());
						
	        aya_printDotDFG(enode_dag, bbnode_dag, opt_cfgOutdir + "/" + fname + "_graph.dot", opt_serialNumber, fix_mc_st_interfaces_flag);
	        printDotCFG(bbnode_dag, (opt_cfgOutdir + "/" + fname + "_bbgraph.dot").c_str());
#endif

          //  circuitGen->sanityCheckVanilla(enode_dag);
        }
    }

    bool runOnFunction(Function& F) override {
		LoopInfo &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
		this->compileAndProduceDOTFile(F, LI); 
    }

    void print(llvm::raw_ostream& OS, const Module* M) const override {}
};
} // namespace

char MyCFGPass::ID = 1;

static RegisterPass<MyCFGPass> Z("mycfgpass", "Creates new CFG pass",
                                 false, // modifies the CFG!
                                 false);

/* for clang pass registration
 */
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"

static void registerClangPass(const PassManagerBuilder&, legacy::PassManagerBase& PM) {
    PM.add(new MyCFGPass());
}

static RegisterStandardPasses RegisterClangPass(PassManagerBuilder::EP_EarlyAsPossible,
                                                registerClangPass);

bool fileExists(const char* fileName) {
    FILE* file = NULL;
    if ((file = fopen(fileName, "r")) != NULL) {
        fclose(file);

        return true;

    } else {

        return false;
    }
}
