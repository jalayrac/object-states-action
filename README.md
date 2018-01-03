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
  wget http://www.di.ens.fr/~alayrac/release_iccv17/features_data.zip
  unzip features_data.zip
  ```

5) Open MATLAB (edit the launch file to select the action you want among 'put_wheel' (default), 'withdraw_wheel', 'open_oyster', 'pour_coffee', 'close_fridge', 'open_fridge' or 'place_plant')

  ```Matlab
  compile.m
  launch.m
  ```

### Data usage

You can download [metadata](http://www.di.ens.fr/~alayrac/release_iccv17/iccv2017_metadata.tar.gz) and the [raw images](http://www.di.ens.fr/~alayrac/release_iccv17/raw_images_iccv2017.tar.gz) (17GB).
Here are some instructions to parse the metadata.
The raw data is organized as follows:

```
action_name -> action_name_clipid -> %06d.jpg
```

The metadata consists of one mat file per action with the following fields:

#### Clip information (in that example we have 191 clips in total):

* `clipids_state:{1x191 cell}`: contains the name of the clip (string). The name of the clips
are of the form action_name_clipdid. The format of clipid is a %04d integer. Be careful,
it can have a larger value than the number of clips (in that case > 191). 
Thanks to this clipid, one can find back the subfolder where to find the images.

#### Object state information 
In that example we have 4016 tracklets in total:

* `clips:[1x191 double]`: contains the number of tracklet for each clip.
* `state_GT:[1x4016 double]`: contains the GT state id for each tracklet 
(see the paper for more details on these 4 labels).

```
	0: False Positive Detections
	1: state_1
	2: state_2
	3: Ambiguous
```

* `vids_state:[1x4016 double]`: contains the id of the clip associated with each tracklet. 
Be careful, this id correspond to the clipid contained in clipids_state (hence it can be greater
than 191 in that case). 
* `FRAMES_state:{1x4016 cell}`: contains the frames ids spanned by the tracklet. 
NB: the frames do not necessarily start at 1 as these clips have been obtained after some cuts 
(see section 5.2 of the paper, Experimental Setup).
* `BOXES_state:{1x4016 cell}`: contains the box detection for each frame. The format 
is `[x1,x2,y1,y2]` in pixel (be careful if you resize the images).
* `T_state:[4016x1 double]`: contains the time (in second) of the tracklet (average over the frames that
are spanned by the tracklet). 

**NB**: the time does not necessarily start at 0 but this is fine. One can recover the i-th entry by just doing:

``` matlab
mean(meta_data.FRAMES_state{i} / fps)
```

**NB**: If you want for example to recover the ground truth of states but regrouped by clip one can simply do:

```Matlab
state_GT_per_clip = mat2cell(meta_data.state_GT', meta_data.clips)
```

This is why `meta_data.clips` can be useful.


#### Action information

Each clip is decomposed over small chunk of 0.4s (10 frames at 25fps). 
Because some videos have an higher or a lower fps the number of frames per chunk may vary. 

In our example, we have 8777 chunks in total. Because different videos 
can have different fps, we provide the id of frames for each chunk.

* `vids_action:[8777x1 double]`: contains the id of the clip associated with the chunk. 
	(in other words it is the equivalent of vids_state but for action).
* `T_action:[8777x1 double]`: contains the time (in second) of each clip.
* `FRAMES_action:{1x8777 cell}`: contains the frames ids spanned by each chunk.
* `action_GT:[8777x1 double]`: contains the GT (0 for background and 1 for the action).

**NB**: if you want to recover the equivalent of meta_data.clips but for action, one can simply do:

```Matlab
[U, Ia, Ic] = unique(meta_data.vids_action)
clips_action = sum(hist(Ic, max(U))
```

It can then be used as before but for actions.








