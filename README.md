# object-states-action
Code for the paper Joint Discovery of Object States and Manipulation Actions, ICCV 2017

Created by Jean-Baptiste Alayrac at INRIA, Paris.

### Introduction

The webpage for this project is available [here](http://www.di.ens.fr/willow/research/objectstates/). It contains link to the [paper](http://www.di.ens.fr/willow/research/objectstates/paper.pdf), and other material about the work.
This code reproduce the results presented in Table 1 of the paper for our method (meaning row **(f)** for state and row **(iv)** for actions).

### License

Our code is released under the MIT License (refer to the LICENSE file for details).

### Cite

If you find this code useful in your research, please, consider citing our paper:

> @InProceedings{Alayrac17objectstates,
>    author      = "Alayrac, Jean-Baptiste and Sivic, Josef and Laptev, Ivan and Lacoste-Julien, Simon",
>    title       = "Joint Discovery of Object States and Manipulation Actions",
>    booktitle   = "International Conference on Computer Vision (ICCV)",
>    year        = "2017"
>}

### Contents

  1. [Requirements](#requirements)
  2. [Running the code](#running)

### Requirements

To run the code, you need MATLAB installed.
The code was tested on Ubuntu 14.04 LTS with MATLAB-2016b.

### Running

1) Clone this repo and go to the generated folder
  ```Shell
  git clone https://github.com/jalayrac/object-states-action.git
  cd object-states-action
  ```

2) Download and unpack the preprocessed features:
  ```Shell
  wget -P data http://www.di.ens.fr/~alayrac/release_iccv17/features_data.zip
  unzip data/features_data.zip -d data
  ```

5) Open MATLAB (edit the launch file to select the action you want among 'put_wheel' (default), 'withdraw_wheel', 'open_oyster', 'close_fridge', 'open_fridge' or 'place_plant')

  ```Matlab
  compile.m
  launch.m
  ```
