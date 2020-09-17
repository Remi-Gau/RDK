[![](https://img.shields.io/badge/Octave-CI-blue?logo=Octave&logoColor=white)](https://github.com/cpp-lln-lab/localizer_visual_motion/actions)
![](https://github.com/cpp-lln-lab/localizer_visual_motion/workflows/CI/badge.svg)

[![codecov](https://codecov.io/gh/cpp-lln-lab/localizer_visual_motion/branch/master/graph/badge.svg)](https://codecov.io/gh/cpp-lln-lab/localizer_visual_motion)

[![Build Status](https://travis-ci.com/cpp-lln-lab/localizer_visual_motion.svg?branch=master)](https://travis-ci.com/cpp-lln-lab/localizer_visual_motion)

<!-- vscode-markdown-toc -->
* 1. [Requirements](#Requirements)
* 2. [Installation](#Installation)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

# motion rdk

##  1. <a name='Requirements'></a>Requirements

Make sure that the following toolboxes are installed and added to the matlab / octave path.

For instructions see the following links:

| Requirements                                             | Used version |
| -------------------------------------------------------- | ------------ |
| [CPP_BIDS](https://github.com/cpp-lln-lab/CPP_BIDS)      | ?            |
| [CPP_PTB](https://github.com/cpp-lln-lab/CPP_PTB)        | ?            |
| [PsychToolBox](http://psychtoolbox.org/)                 | >=3.0.14     |
| [Matlab](https://www.mathworks.com/products/matlab.html) | >=2017       |
| or [octave](https://www.gnu.org/software/octave/)        | >=4.?        |

##  2. <a name='Installation'></a>Installation

The CPP_BIDS and CPP_PTB dependencies are already set up as submodule to this repository.
You can install it all with git by doing.

```bash
git clone --recurse-submodules https://github.com/cpp-lln-lab/localizer_visual_motion.git
```

