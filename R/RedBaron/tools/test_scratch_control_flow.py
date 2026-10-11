import unittest
from scratch_control_flow import dominance


class ScratchFlowTests(unittest.TestCase):
    def test_both_conditional_paths_pass_fresh_store(self):
        graph={0:[1],1:[2,3],2:[4],3:[4],4:[5,6],5:[6],6:[]}
        self.assertEqual(dominance(graph,0,1,5),7)

    def test_bypass_is_rejected_even_when_other_path_assigns(self):
        graph={0:[1,3],1:[2],2:[3],3:[]}
        with self.assertRaises(ValueError):dominance(graph,0,1,3)

    def test_unreachable_reader_and_external_edge_are_rejected(self):
        for graph in ({0:[1],1:[],2:[]},{0:[1],1:[2],2:[3]}):
            with self.assertRaises(ValueError):dominance(graph,0,1,2)

    def test_loop_does_not_hide_bypass(self):
        graph={0:[1],1:[2],2:[2,3],3:[]}
        self.assertEqual(dominance(graph,0,1,3),4)
        graph[0].append(2)
        with self.assertRaises(ValueError):dominance(graph,0,1,3)
