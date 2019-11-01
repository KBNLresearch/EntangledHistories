# Transkribus
Processing of Transkribus output using xslt and running it through Annif

This repository was created in the context of the Entangled Histories project of Annemieke Romein, Researcher in Residence at the KB in 2019 (May-October). Read about it here: https://lab.kb.nl/about-us/blog/digital-humanities-and-legal-history-can-computer-read-and-classify-ordinances


The repo holds code for converting the 'page' output of Transkribus, a tool for transcribing handwritten text that we successfully applied to early-modern printed materials. The books we transcribed consisted of legislation, and the xslt-stylsheets in this repo convert the page xmls (one file per page) to a single xml-file containing the text content of the laws. 

As a subsequent step, this xml is loaded into a Jupyter Notebook (CompareToGT.ipynb) together with the gold standard. Here, the xslt-processing is evaluated (seeing what laws are correctly captured). Also, the manual topic annotations from the gold standard are assigned to the laws so that they may serve as training data (the directory 'annif-data') for Annif, an automated subject indexing tool. 

Finally, Annif is run in a cross-validation set-up and the results are combined and evaluated in the directory called 'server-output'.

