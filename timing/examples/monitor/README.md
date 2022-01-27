# Introduction

This example illustrates an advanced technique for reducing fanout on reset signals by creating a register tree that distributes the reset to replicated pipelines across multiple cycles. This optimization usually only makes sense for very large examples. For this example, the illustrated technique does not significantly improve timing. 

All code is provided in src/replicated_pipeline.sv. 

# Instructions

1. In Quartus, open the replicated_pipeline.qpf project.
1. Open the src/replicated_pipeline.sv.
1. Go to the bottom of the file and find the replicated_pipeline module. This modules acts as a top level that lets you change which implementation is used.
1. Make sure the replicated_pipeline_full_reset module is instantiated from the replicated_pipeline module by uncommenting it. Make sure all other instantiations are commented out.
1. Compile the design and check the clock frequencies.
1. Change the replicated_pipeline module to instantiate replicated_pipeline_reset_tree.
1. Compile the design and check the new clock frequencies. For this example, they won't be significantly different, which isn't unexpected for a small design.


