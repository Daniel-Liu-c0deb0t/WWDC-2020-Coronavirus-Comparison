/*:
 # WWDC 2020: Coronavirus Comparison
 
 __Please excuse any slowness! It may take up to 1-2 minutes for every comparison to finish running!__
 
 ## Motivation
 The 2019 coronavirus (SARS-CoV-2) pandemic is a major event in this new decade. There are millions of cases world-wide caused by this highly contagious coronavirus disease (COVID-2019). Therefore, understanding this virus is very important. In this WWDC project, I compare the 2019 coronavirus to a couple of other similar viruses by looking at their sequenced RNA genomes.
  
 ## Overview
 First, let us define the "base virus" as a sample of the 2019 coronavirus from a human host in Illinois. We will examine the relationship between this base virus and a couple of other samples that were sequenced by researchers. These sequences were available in FASTA format and they were retrieved from the National Center for Biotechnology Information's GenBank database:
 
 * __Illinois SARS-CoV-2__, human host from Illinois in 2020 __(our base virus)__
 * __Wuhan SARS-CoV-2__, human host from Wuhan seafood market in 2019
 * __Human SARS-CoV__, human host from Toronto in 2003
 * __Bat SARS-CoV__, bat host from China in 2015
 * __Human CoV 229E__, human host from Seattle in 2015
 * __Human MERS-CoV__, human host from Saudi Arabia in 2019
 * __Camel MERS-CoV__, camel host from United Arab Emirates in 2014
 
 You can select each virus genome at the very top to compare it with the base virus. White buttons indicate that they can be selected. Some buttons may be grayed out if their alignment has not been computed yet. This may take a few seconds to a few minutes.
 
 Underneath the buttons, the percentage match between the base virus and your selected virus is displayed. Under the percentage, the entire genome of the base and the selected viruses are shown, with their differences marked. At the very bottom, the actual nucleotides are shown in a horizontal scrolling box.
 
 The virus genomes are compared by computing their alignment and their edit distance. The edit distance (sometimes called the Levenshtein distance) between two sequences is the number of character substitutions, insertions, and deletions (edits) to get from one sequence to the other. The alignment is just the actual edit operations. Computing edit distances is a very well known computer science problem, and it is very useful in bioinformatics and text retrieval (Google search, etc.). Below, I will present the interesting ideas used in this WWDC project for efficiently computing edit distances. This will demostrate that bioinformatics can be done in Swift.
 
 ## The Challenge
 With coronavirus genomes reaching up to almost 30,000 nucleotides in length, aligning them will take a __significant__ amount of time. With the basic dynamic programming edit distance algorithm, this takes around __900 million__ operations and storing __900 million__ numbers in an array (repeated 6 times for comparing 6 different virus genomes!). This is __way too inefficient__ for a ~3 minute demo. Much of this project is dedicated to push Swift to the limit and calculate the alignments in real time. Below, I briefly describe the algorithmic tricks used:
 
 * Custom bit vector class for space efficiency. This is used for the virus genomes as well as storing the edits as a graph for backtracing to figure out the alignments.
 * Cleverly reuse and overwrite only two rows in the dynamic programming (DP) matrix.
 * Calculating cells in the DP matrix near the main diagonal, based on some threshold `k`. Perform exponential search for `k`.
 * Prune diagonals to the left and to the right of the main diagonal in the DP matrix based on Ukknonen's speedup trick.
 * Upper bound `k` by first calculating the Hamming distance (number of mismatches, very fast) between two sequences.
 * Multithreading to compare genomes independently. Each genome comparison is available to be visualized when it is done computing.
 
 ## Limitations
 For a serious analysis please use a well-established tool like BLAST. This project is merely a demostration of the algorithms and a visualization of the differences between coronavirus genomes.
 
 ## About Me
 I am a high school student interested in computer science algorithms and I do research in bioinformatics and deep learning security. This is my first time creating a Swift project!
 */

let shouldShowMismatches = false

import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

initVars(shouldShowMismatches: shouldShowMismatches)

let controller = WWDCViewController()
controller.preferredContentSize = CGSize(width: viewWidth, height: viewHeight)

// after creating UI, so buttons are available
calcOtherDistances(controller: controller)

PlaygroundPage.current.liveView = controller
