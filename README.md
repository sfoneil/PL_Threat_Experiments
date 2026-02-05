# MATLAB & Octave experiments using eye tracking to assess arousal and vigilance to threatening stimuli.
Works with Pupil Labs Core eye tracker (https://pupil-labs.com/products/core)

## Requirements:
1. MATLAB 2024b or older, newer versions have abandoned Java-dependency and may not be compatible.
2. JeroMQ on path (https://github.com/zeromq/jeromq) - see readme.

## Main experiments:
1. `Arousal_new.m` - measure pupilometric responses to auditory stimuli presented for 4 seconds. Stimuli are one trial block of 24 non-threat stimuli (water sounds) and 2 blocks of 24 threat sounds (human screams).
2. `ThreatVigilance1.m` - measure eye movements and fixations to images of neutral and high-affective (shocking or disturbing) images from Weierich et al. Complex Affective Scene Set (COMPASS; https://www.compass-scenes.com)
Images presented in 3 blocks of 15 different images (45 total) for 10 seconds each.
6. `VigilanceBaseline.m` - 5 minute block of a fixation cross for baseline eye movement measurement

## Resources
### Dependent code
1. `drawFix.m` - code for drawing fixation cross across experiments.

### Audio resources
Six audio files. Processed in Audacity **NOTES**
- threat_audio - Folder with threat sounds (screams)
  - `scream1.wav`
  - `scream2.wav`
  - `scream3.wav`
- safety_audio - Folder with safety sounds (water)
  - `water1.wav`
  - `water2.wav`
  - `water3.wav`

### Trial information
- trial_runs - Folder
  - templates - Folder containing default runs. Current experiment version runs each block in a fixed order, but the experimenter specifies order of blocks (baseline water sounds / threat sounds / threat sounds with handholding)
    - `run1.mat`
    - `run2.mat`
    - `run3.mat`
  - `MakeRun_et.m` - code to create new run sessions/randomization. Current version has fixed order within blocks, order of blocks is specified in Command Window at start. 

## Resources and other files
1. instructions for install.txt - readme for setting up a new computer/MATLAB for JeroMQ messaging.
2. `jmq_rec.m` - example code for working with JeroMQ messages.
