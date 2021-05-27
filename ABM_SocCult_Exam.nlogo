;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;       GLOBALS AND PATCH/AGENT PROPERTIES        ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


globals [                 ;; what are some overarching variables of the population?
;  N                     ; Number of agents.
  count_1               ; Count of agents belonging to the two groups -1 and 1.
  count_0
  count_-1
  count_left
  count_mid_left
  count_middle
  count_mid_right
  count_right
  opinion_distances     ; Vector of the differences in opinion of each agent (of a sample) from every other agent (of the sample).
  ok_polarization_index ; If true, allows the computation of the polarization index.
  ok_groups'_measures   ; If true, allows the computation of indices concerning the 2 groups.
  sample_set            ; Set of agents sampled for the measurement of the polarization index
  sample_size
  polarization_index    ; The following variables are all the computed measures.
  dissimilarity_index
  samples_dissimilarity_index
  mean_opinion_global
  mean_opinion_group_1
  mean_opinion_group_0
  mean_opinion_group_-1
  var_opinion_global
  var_opinion_group_1
  var_opinion_group_0
  var_opinion_group_-1
  sd_opinion_global
  sd_opinion_group_1
  sd_opinion_group_0
  sd_opinion_group_-1
  mean_opinion_left
  var_opinion_left
  sd_opinion_left
  mean_opinion_mid_left
  var_opinion_mid_left
  sd_opinion_mid_left
  mean_opinion_middle
  var_opinion_middle
  sd_opinion_middle
  mean_opinion_mid_right
  var_opinion_mid_right
  sd_opinion_mid_right
  mean_opinion_right
  var_opinion_right
  sd_opinion_right
  extremists
  count_extremists
  count_extremists_1
  count_extremists_-1
  local_difference_neighborhood_mean
  local_difference_ingroup_mean
  local_difference_outgroup_mean
  d_max
  %_ingroup_size
  cells_in_radius
  size_buffer
  count_turtles         ; For data export
  precisionN            ;      "
  ID                    ;      "
  neighborhood_size
  weight
  possible_neighbors
  %_extremists
  %_extremists_1
  %_extremists_-1
  patch1
  patch2
  cluster_list
  iterations_max
  iterations_max_rounded
  left_count
  mid_left_count
  mid_count
  mid_right_count
  right_count
  left_count_rounded
  mid_left_count_rounded
  mid_count_rounded
  mid_right_count_rounded
  right_count_rounded
  output-filename
]

patches-own
[
  turtles_poss_spot_nearby
  turtles_poss_spot_nearby_count
  other_poss_spot_nearby
  other_poss_spot_nearby_count
  possible_spot?
  better_spot?
  low_satisfactory_spot?
  satisfactory_spot?
]

turtles-own
[
  cooperative
  cooperative?
  happy?
  opinion         ; An agent's opinion
  group           ; An agent's group
  j               ; Each agent's interaction partner, randomly picked from its neighborhood
  j_opinion       ; Opinion of an agent's interaction partner
  j_group         ; Group of an agent's interaction partner
  delta_opinion
  a
  neighborhood    ; List of sorrounding agents (in other words, an agent's interaction network)
  count_neighbors ; Number of agents comprised in a neighborhood
  raw_opinion_changes
  sample_for_polarization_index
  mylist
  neighborhood_turtles
  neighborhood_turtles_count
  mycolor
  other_nearby
  other_nearby_count
  target
  colorlist
  mygroup
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;           PROCEDURES            ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to setup
  clear-all
  reset-ticks
   let my-seed new-seed            ;; generate a new seed
   output-print word "Generated seed: " my-seed  ;; print it out
   random-seed my-seed             ;; use the new seed
;  random-seed "X"                ;; for reproducing: insetad of X --> add number that was set as seed, comment out 3 lines above
  setup-targets
  setup-turtles
  setup-turtle-opinion-color
  setup-iterations
  setup-clusters
  set output-filename "output-data.csv"
  initialize-data-file
end



to go
  ask turtles [
        set neighborhood_turtles turtles in-radius Radius
        set neighborhood_turtles_count count neighborhood_turtles ]
  interact-turtles                ;; the turtles interact with each other and influecne each other's attribute scores
  move-unhappy-turtles
  tick
  if (ticks mod 10 ) = 0 [compute-measures]
  if ticks = 2921 [stop]
  ask turtles [
     if output-data? [
      if ticks = 1 or ticks mod output-every-n-ticks = 0  [       ;;output-every-n-ticks
        write-output-data who opinion
      ]
    ]
  ]
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;         SETUP FUNCTIONS         ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup-targets
  ask patches [set pcolor white]
  set patch1 patch 8 8
  set patch2 patch 25 25
  set cluster_list list patch1 patch2
end


to setup-turtles
  create-turtles turtle_number [
    setxy random-xcor random-ycor ;]
    set shape "person"
    set size 1
    set target one-of cluster_list
    face target
  ]
end


to setup-turtle-opinion-color
  ask turtles [
  set left_count %_opinion_left * turtle_number
  set left_count_rounded round left_count

  set mid_left_count %_opinion_mid_left * turtle_number
  set mid_left_count_rounded round mid_left_count

  set mid_count %_opinion_middle * turtle_number
  set mid_count_rounded round mid_count

  set mid_right_count %_opinion_mid_right * turtle_number
  set mid_right_count_rounded round mid_right_count

  set right_count %_opinion_right * turtle_number
  set right_count_rounded round right_count
  ]
  ask n-of left_count_rounded turtles [
           set color 105
           set opinion (-1 + random-float ((2 / 11) * 2)) ]              ;; x/11: depending on how many of the ESS scores are included in that opinion category. With 11 ess score options, this way opinion size is proportionate to the population as it was in the ESS sample
  ask n-of mid_left_count_rounded turtles [
           set color 107
           set opinion ( -1 + ((2 / 11) * 2) + random-float ((3 / 11) * 2)) ]
  ask n-of mid_count_rounded turtles [
           set color 55
           set opinion (-1 + ((5 / 11) * 2) + random-float ((1 / 11) * 2)) ]
  ask n-of mid_right_count_rounded turtles [
           set color 17
           set opinion (-1 + ((6 / 11) * 2) + random-float ((3 / 11) * 2)) ]
  ask n-of right_count_rounded turtles [
           set color 15
           set opinion (-1 + ((9 / 11) * 2) + random-float ((2 / 11) * 2)) ]
 ask turtles [
     if color != 105 and color != 107 and color != 55 and color != 17 and color != 15 [              ;; ACCOUNTING FOR LEFTOVERS AFTER ROUNDING in the prev steps
           set colorlist [15 17 105 107 55]
           set color one-of colorlist
           if color = 105 [ set opinion  (-1 + random-float ((2 / 11) * 2)) ]
           if color = 107 [ set opinion ( -1 + ((2 / 11) * 2) + random-float ((3 / 11) * 2)) ]
           if color = 55 [ set opinion (-1 + ((5 / 11) * 2) + random-float ((1 / 11) * 2)) ]
           if color = 17 [ set opinion (-1 + ((6 / 11) * 2) + random-float ((3 / 11) * 2)) ]
           if color = 15 [ set opinion (-1 + ((9 / 11) * 2) + random-float ((2 / 11) * 2)) ]
      ]]
  ask turtles [                                                                                      ;; setting the initial group of each turtle (based on their opinion)
    if opinion < -1 + ((5 / 11) * 2) [ set group -1 ]
    if opinion >= -1 + ((5 / 11) * 2) and opinion <= -1 + ((6 / 11) * 2) [set group 0]
    if opinion < -1 + ((6 / 11) * 2) [set group 1]
  ]
end


to setup-iterations
  set iterations_max Gini-coefficient * 20
  set iterations_max_rounded round iterations_max
end


to setup-clusters
  repeat iterations_max_rounded [
    ask turtles [
      if distance target > 1 and not any? other turtles-on patch-ahead 1 [
        fd 1
       ]
      ]
     ]
end

to initialize-data-file
  if output-data?
  [
    file-close-all
    if behaviorspace-run-number <= 1 [
      if file-exists? output-filename [
        file-delete output-filename
      ]
      file-open output-filename
      file-print (word "run-number, ticks, turtle-id, opinion" )
    ]
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;          GO FUNCTIONS           ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; H : during an interaction between two agents, this parameter defines the relative importance of the difference in agents’
;;     group belonging and the difference in their opinion in in determining the weight of the interaction
;; M: This parameter has range [0, 1]. during an interaction between two agents, M defines the relative strength of the two mechanisms
;;     (negative influence and persuasive arguments) in determining how agents update their opinion. In other words, this parameter serves
;;     as a switch between the two mechanisms
;; S: agent's "memory"
;; more about each of these on the interface

to interact-turtles
  ask turtles [
    set j one-of neighborhood_turtles
    set j_opinion [ opinion ] of j
    set j_group [ group ] of j
    update-weight
    update-raw-opinion-change
    update-opinion-and-group ]
end


to update-weight
      set weight (1 - ((abs (j_opinion - opinion) * H + abs (j_group - group )) / ( 1 + H ) ))
end


to update-raw-opinion-change
  set delta_opinion ((( 0.5 * (j_opinion - opinion) * weight ))) ;* 0.85 ) + (( a * ((weight + 1) / 2 )))* 0.15 ) ; / (M + ( 1 - M ))
end



to update-opinion-and-group
  ifelse opinion < -0.7 and j_opinion < -0.7 [
    set delta_opinion abs delta_opinion
    set opinion opinion - delta_opinion ]
   [ ifelse opinion > 0.7 and j_opinion > 0.7 [
    set delta_opinion abs delta_opinion
    set opinion opinion + delta_opinion ]
    [ set opinion opinion + delta_opinion ]
   ]
  if opinion > 1 [ set opinion 1 ]
  if opinion < -1 [set opinion -1 ]
  if opinion <=  -1 + ((2 / 11) * 2) [set color blue]
  if opinion > -1 + ((2 / 11) * 2) and opinion < -1 + ((5 / 11) * 2) [set color blue + 2]
  if opinion >= -1 + ((5 / 11) * 2) and opinion <= 1 - ((5 / 11) * 2) [set color green]
  if opinion > 1 - ((5 / 11) * 2) and opinion < 1 - ((2 / 11) * 2) [set color red + 2]
  if opinion >= 1 - ((2 / 11) * 2) [set color red]
  if opinion < -1 + ((5 / 11) * 2) [ set group -1 ]
  if opinion >= -1 + ((5 / 11) * 2) and opinion <= -1 + ((6 / 11) * 2) [set group 0]
  if opinion < -1 + ((6 / 11) * 2) [set group 1]
end



to move-unhappy-turtles
  ask turtles [ calculate-happiness ]
  ask patches [identify-possible-spots]
  ask patches with [possible_spot? = true] [setup-for-calculate-better-spots]
  ask patches with [possible_spot? = true] [ calculate-better-spots ]
  ask turtles with [group = -1 ] [ move-turtles]
  ask turtles with [group = 1 ] [ move-turtles]
end


to calculate-happiness
  if neighborhood_turtles_count >= 1 [                                                  ;; if there are turtles in my neighborhood:
      set mycolor color
      set other_nearby neighborhood_turtles with [color != mycolor]                      ;; total number of outgroup turtles in my neighborhood
      set other_nearby_count count other_nearby
      ifelse ( other_nearby_count / neighborhood_turtles_count ) >= Tolerance_threshold [set happy? false] [set happy? true]                   ;; if there are more "other opinion" turtles in my neighborhood than I can tolerate,than I am not happy:
  ]
end


to identify-possible-spots
  ifelse count turtles-here = 0  [set possible_spot? true] [set possible_spot? false]
;    set possible_spots patches with [ count turtles-here = 0 ]                    ;; I first identify the empty spots ("possible_spots"), to which turtles are allowed to move if they are unhappy on their current spot.
end

to setup-for-calculate-better-spots
    set turtles_poss_spot_nearby turtles in-radius Radius ; of possible_spots     ;; Then I identify the turtles in the neighborhood of the possible_spots ("turtles_poss_spot_nearby")
    set turtles_poss_spot_nearby_count count turtles_poss_spot_nearby ;]            ;; and finally I try to count the turtles that are in the neighborhood  of each possible_spot ("turtles_poss_spot_nearby_count")
    set other_poss_spot_nearby turtles with [color != mycolor] in-radius Radius
    set other_poss_spot_nearby_count count other_poss_spot_nearby
end

to calculate-better-spots
   ifelse other_poss_spot_nearby_count < ( turtles_poss_spot_nearby_count * (Tolerance_threshold - 0.2 ) )
      [set better_spot? true] [set better_spot? false]
   ifelse other_poss_spot_nearby_count < ( turtles_poss_spot_nearby_count * ( Tolerance_threshold - 0.1 ) )
      [set satisfactory_spot? true] [set satisfactory_spot? false]
   ifelse other_poss_spot_nearby_count < (turtles_poss_spot_nearby_count * Tolerance_threshold)
      [set low_satisfactory_spot? true] [set low_satisfactory_spot? false]
end



to move-turtles
  if not happy? [
        ifelse any? patches with [better_spot? = true]
    [  move-to one-of patches with [better_spot? = true] in-radius Moving_max_distance_radius]
    [ ifelse any? patches with [satisfactory_spot? = true]
      [ move-to one-of patches with [satisfactory_spot? = true] in-radius Moving_max_distance_radius]
                [  ifelse any? patches with [satisfactory_spot? = true]
      [ move-to one-of patches with [low_satisfactory_spot? = true] in-radius Moving_max_distance_radius ]
          [ ;; else command
         move-to one-of patches with [possible_spot? = true] in-radius Moving_max_distance_radius]
]]]
end



to write-output-data [ #turtle-id #opinion ]
  file-open output-filename
  file-print (word  behaviorspace-run-number ", " ticks ", " #turtle-id ", " #opinion )
  file-flush
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;         Computation of indexes         ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to compute-measures
  calculate-mean-var                        ;; calculates mean and variance for all turtles and for the 2 groups
  setup-samples                             ;; takes a sample of all turtles. This sample is needed to calculate polarization index.
  calculate-polarization-index              ;; calculates polarization index
  count-extremist-%                         ;; calculates the % of agents that have an opinion -1 - -0.9, or 0.9 - 1 (opinion that are at the very edges of the opinion scale)
end


to calculate-mean-var
  set count_1 count turtles with [group = 1]
  set count_0 count turtles with [group = 0]
  set count_-1 count turtles with [group = -1]

  set count_left count turtles with [color = 105]
  set count_mid_left count turtles with [color = 107]
  set count_middle count turtles with [color = 55]
  set count_mid_right count turtles with [color = 17]
  set count_right count turtles with [color = 15]

  set precisionN 5

  set mean_opinion_global precision ( mean [opinion] of turtles ) precisionN
  set sd_opinion_global precision ( standard-deviation [opinion] of turtles ) precisionN
  set var_opinion_global precision ( variance [opinion] of turtles ) precisionN

; descriptive stats of groups
  if count_1 > 1 [
    set mean_opinion_group_1 precision ( mean [opinion] of turtles with [group = 1] ) precisionN
    set var_opinion_group_1 precision ( variance [opinion] of turtles with [group = 1] ) precisionN
    set sd_opinion_group_1 precision ( standard-deviation [opinion] of turtles with [group = 1] ) precisionN
  ]
  if  count_0 > 1 [
    set mean_opinion_group_0 precision ( mean [opinion] of turtles with [group = 0] ) precisionN
    set var_opinion_group_0 precision ( variance [opinion] of turtles with [group = 0] ) precisionN
    set sd_opinion_group_0 precision ( standard-deviation [opinion] of turtles with [group = 0] ) precisionN
  ]
  if count_-1 > 1 [
    set mean_opinion_group_-1 precision ( mean [opinion] of turtles with [group = -1] ) precisionN
    set var_opinion_group_-1 precision ( variance [opinion] of turtles with [group = -1] ) precisionN
    set sd_opinion_group_-1 precision ( standard-deviation [opinion] of turtles with [group = -1] ) precisionN
  ]

; descriptive stats of opinion groups (color)
  if count_left > 1 [
    set mean_opinion_left precision ( mean [opinion] of turtles with  [color = 105] ) precisionN
    set var_opinion_left precision ( variance [opinion] of turtles with  [color = 105]) precisionN
    set sd_opinion_left precision ( standard-deviation [opinion] of turtles with  [color = 105] ) precisionN
    ]
  if count_mid_left > 1 [
    set mean_opinion_mid_left precision ( mean [opinion] of turtles with [color = 107]) precisionN
    set var_opinion_mid_left precision ( variance [opinion] of turtles with [color = 107]) precisionN
    set sd_opinion_mid_left precision ( standard-deviation [opinion] of turtles with [color = 107]) precisionN
    ]
  if  count_middle > 1 [
    set mean_opinion_middle precision ( mean [opinion] of turtles with [color = 55] ) precisionN
    set var_opinion_middle precision ( variance [opinion] of turtles with [color = 55]) precisionN
    set sd_opinion_middle precision ( standard-deviation [opinion] of turtles with [color = 55] ) precisionN
    ]
  if count_mid_right > 1 [
    set mean_opinion_mid_right precision ( mean [opinion] of turtles with [color = 17] ) precisionN
    set var_opinion_mid_right precision ( variance [opinion] of turtles with [color = 17] ) precisionN
    set sd_opinion_mid_right precision ( standard-deviation [opinion] of turtles with [color = 17] ) precisionN
    ]
  if count_right > 1 [
    set mean_opinion_right precision ( mean [opinion] of turtles with [color = 15]) precisionN
    set var_opinion_right  precision ( variance [opinion] of turtles with [color = 15] ) precisionN
    set sd_opinion_right  precision ( standard-deviation [opinion] of turtles with [color = 15] ) precisionN
    ]
end

to setup-samples
  let N count turtles
  if Sample_size_for_polarization_index = 1 [ set Sample_size_for_polarization_index 0 ]
  if Sample_size_for_polarization_index > N [ set Sample_size_for_polarization_index N ]
  ask n-of Sample_size_for_polarization_index turtles [ set sample_for_polarization_index 1 ]
  set sample_set turtles with [ sample_for_polarization_index = 1 ]
  if Sample_size_for_polarization_index > 1 [ set ok_polarization_index 1]
  if Sample_size_for_polarization_index > 200 [
    ifelse Sample_size_for_polarization_index > 500
    [
      user-message (word "The sample for polarization index is very big. Its size has been automatically reduced to 200")
      set Sample_size_for_polarization_index 200
    ]
    [
      user-message (word "The sample for polarization index is very big. Consider decreasing the 'Sample_size_for_polarization_index' and then click on 'Setup'")
    ]
  ]
end


to calculate-polarization-index
  set precisionN 5                            ;; reports number rounded to 5 decimals
  if ok_polarization_index = 1 [
    set opinion_distances [ ]                   ;; LOOK INTO HOW WE GET OPINION DISTANCES
    ask sample_set [
      let my_opinion opinion
      ask sample_set with [ distance myself > 0 ] [
        set opinion_distances lput ( abs ( my_opinion - opinion )) opinion_distances
      ]
    ]
        set polarization_index precision ( variance opinion_distances ) precisionN
  ]
end


to count-extremist-%
  let N count turtles
  set extremists turtles with  [ opinion > 0.9 or opinion < -0.9 ]
  set count_extremists count extremists
  set count_extremists_1 count extremists with [ group = 1 ]
  set count_extremists_-1 count extremists with [ group = -1 ]
  set %_extremists (count_extremists / N) * 100
  set %_extremists_1 (count_extremists_1 / N) * 100
  set %_extremists_-1 (count_extremists_-1 / N) * 100
end
@#$#@#$#@
GRAPHICS-WINDOW
511
31
948
469
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
60.0

SLIDER
29
27
201
60
turtle_number
turtle_number
0
1000
300.0
1
1
NIL
HORIZONTAL

BUTTON
357
25
420
58
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
426
25
489
58
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
26
277
198
310
H
H
0
2
1.0
0.05
1
NIL
HORIZONTAL

SLIDER
30
125
202
158
Radius
Radius
0
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
30
175
202
208
Tolerance_threshold
Tolerance_threshold
0
1
0.5
0.05
1
NIL
HORIZONTAL

SLIDER
984
32
1230
65
sample_size_for_polarization_index
sample_size_for_polarization_index
1
200
200.0
1
1
NIL
HORIZONTAL

PLOT
1030
79
1230
229
Polarization index
tick
polarization
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot polarization_index"

TEXTBOX
214
29
364
47
Number of people (\"turtles\")
11
0.0
1

TEXTBOX
212
275
362
387
The relative importance\nof group identification\nand opinion in determining\nthe weight of the other\nperson in an interaction.
11
0.0
1

TEXTBOX
210
127
360
155
The radius of patches that make up a \"neighborhood\"
11
0.0
1

TEXTBOX
212
172
362
242
How many people with differing opinions you tolerate in your neighborhood, before moving to find a new spot.
11
0.0
1

PLOT
1005
500
1205
650
% of people with extreme opinions
tick
%
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot %_extremists"
"pen-1" 1.0 0 -2674135 true "" "plot %_extremists_1"
"pen-2" 1.0 0 -13345367 true "" "plot %_extremists_-1"

TEXTBOX
209
265
359
283
NIL
11
0.0
1

TEXTBOX
1032
231
1182
273
The variance in the distribution of the differences in opinion between agents.
11
0.0
1

SLIDER
29
75
201
108
Gini-coefficient
Gini-coefficient
0
1
0.2
0.001
1
NIL
HORIZONTAL

TEXTBOX
213
70
363
154
Level of income inequality.\n0 = perfect equality\n1 = prefect inequality
11
0.0
1

TEXTBOX
344
71
494
113
The higher the inequality, the more clustered people will be in the world.
11
0.0
1

TEXTBOX
345
274
495
316
The lower H (H < 1), the stronger effect group ident. has on the interaction.
11
0.0
1

TEXTBOX
35
234
185
264
Interaction settings for opinion updating
12
0.0
1

INPUTBOX
32
517
187
577
%_opinion_left
0.1
1
0
Number

INPUTBOX
193
517
348
577
%_opinion_mid_left
0.2
1
0
Number

INPUTBOX
352
517
507
577
%_opinion_middle
0.4
1
0
Number

INPUTBOX
513
517
668
577
%_opinion_mid_right
0.2
1
0
Number

INPUTBOX
673
516
828
576
%_opinion_right
0.1
1
0
Number

TEXTBOX
846
518
996
602
ESS left-right scale:\n0-1 = left\n2-4 = mid-left\n5 = middle\n6-8 = mid-right\n9-10 = right
11
0.0
1

PLOT
997
292
1197
442
Super combined plot
tick
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"mean_opinion_global" 1.0 0 -10603201 true "" "plot mean_opinion_global"
"var_opinion_global" 1.0 0 -7713188 true "" "plot var_opinion_global"
"sd_opinion_global" 1.0 0 -4757638 true "" "plot sd_opinion_global"
"mean_opinion_group_1" 1.0 0 -12186836 true "" "plot mean_opinion_group_1"
"var_opinion_group_1" 1.0 0 -10022847 true "" "plot var_opinion_group_1"
"sd_opinion_group_1" 1.0 0 -7858858 true "" "plot sd_opinion_group_1"
"mean_opinion_group_0" 1.0 0 -13360827 true "" "plot mean_opinion_group_0"
"var_opinion_group_0" 1.0 0 -11783835 true "" "plot var_opinion_group_0"
"sd_opinion_group_0" 1.0 0 -10141563 true "" "plot sd_opinion_group_0"
"mean_opinion_group_-1" 1.0 0 -15390905 true "" "plot mean_opinion_group_-1"
"var_opinion_group_-1" 1.0 0 -14730904 true "" "plot var_opinion_group_-1"
"sd_opinion_group_-" 1.0 0 -14070903 true "" "plot sd_opinion_group_-1"
"mean_opinion_left" 1.0 0 -15582384 true "" "plot mean_opinion_left"
"var_opinion_left" 1.0 0 -14985354 true "" "plot var_opinion_left"
"sd_opinion_left" 1.0 0 -14454117 true "" "plot sd_opinion_left"
"mean_opinion_mid_left" 1.0 0 -14462382 true "" "plot mean_opinion_mid_left"
"var_opinion_mid_left" 1.0 0 -13403783 true "" "plot var_opinion_mid_left"
"sd_opinion_mid_left" 1.0 0 -12345184 true "" "plot sd_opinion_mid_left"
"mean_opinion_middle" 1.0 0 -15973838 true "" "plot mean_opinion_middle"
"var_opinion_middle" 1.0 0 -15637942 true "" "plot var_opinion_middle"
"sd_opinion_middle" 1.0 0 -15302303 true "" "plot sd_opinion_middle"
"mean_opinion_mid_right" 1.0 0 -15575016 true "" "plot mean_opinion_mid_right"
"var_opinion_mid_right" 1.0 0 -15040220 true "" "plot var_opinion_mid_right"
"sd_opinion_mid_right" 1.0 0 -14439633 true "" "plot sd_opinion_mid_right"
"mean_opinion_right" 1.0 0 -14333415 true "" "plot mean_opinion_right"
"var_opinion_right" 1.0 0 -13210332 true "" "plot var_opinion_right"
"sd_opinion_right" 1.0 0 -12087248 true "" "plot sd_opinion_right"
"polarization_index" 1.0 0 -2674135 true "" "plot polarization_index"
"%_extremists" 1.0 0 -10263788 true "" "plot %_extremists"
"%_extremists_1" 1.0 0 -7171555 true "" "plot %_extremists_1"
"%_extremists_-1" 1.0 0 -4079321 true "" "plot %_extremists_-1"

SLIDER
29
367
241
400
Moving_max_distance_radius
Moving_max_distance_radius
0
20
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
257
370
407
440
A higher Gini-coefficient makes it harder to move out of your cluster, so it requires a smaller radius in which agents can move.
11
0.0
1

OUTPUT
28
445
268
499
11

SWITCH
38
600
166
633
output-data?
output-data?
0
1
-1000

SLIDER
40
645
212
678
output-every-n-ticks
output-every-n-ticks
0
2921
1460.0
10
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
