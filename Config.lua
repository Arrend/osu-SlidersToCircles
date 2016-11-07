--User preferences on how the script should run.
--The first
local off, on = false, true
local Config = {
  --All config is ignored in One Circle
  --Min Time Between Circles
  --Streams: No stream will be above the bpm given by this (the bpm will be halved until the time between circles is above or equal to this value)
  Minms={off, 62.5}, --BPM -> ms = 15000/bpm  (for 1/4)

  --Max Time Between Circles
  --Streams: No stream will be below the bpm given by this (the bpm wil be doubled until the time between the circles is below or equal to this value)
  Maxms={off, 125}, --BPM -> ms = 15000/bpm   (for 1/4)

  --Min Slider Length for a slider to get replaced
  --This is to remove kickslider jumps becoming 1/4 bpm jumps
  Minlen={on, 125}, --BPM -> ms = 15000/bpm    (for 1/4)

  --Max Slider Length for a slider to get replaced
  --Removes long pauses and deathstreams
  Maxlen={off, 4000}, --BPM -> ms = (15000/bpm)  (for 1/4)

  --Long Streams Half Speed
  --Streams: A slider which would have more notes than the given value is instead a half bpm stream
  Strmhf={off, 33},

  --1/4 Sliders replaced with Stacks
  --Two Circles, Streams: Stacks both slider circles on the starting slider circle position
  --Streams: 2nd element determines bpm override
  O4fstck={off, on},

  --1/3 Stream Preference
  --Streams: If both 1/4 and 1/3 divide into the slider length then 1/3 will be chosen over 1/4
  O3pref={off},

  --Stream Multiplier
  --Streams: All created streams will have their bpm multiplied by 2 to the power of the second element
  Strmpl={off, 0},

  --Ignore repeat sliders
  Rptign={off},

  --Stream Hitsounding
  --Streams: 0 = Auto hitsounds, taken from slider slide hitsound; 1 = whistle; 2 = finish; 3 = clap
  Strmhs={off, 0},

  --Metadata Overrides
  --Overrides metadata with the given value
  Mtdtov={
    --{"ApproachRate:", 10}      Look up the line in the .osu file, and give its override
  }
}

return Config
