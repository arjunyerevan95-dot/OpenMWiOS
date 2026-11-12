# Current-frame diagnostic only

Preserves the WO40 workflow and source baseline. Separate app identity; no automatic installation or save migration. Presents the current PBO rather than prior PBO, retaining the existing fence/readback mechanism. This may reduce latency at the cost of throughput. Default true only in this diagnostic branch; hint can select original behavior. Existing fence timeout handling is unchanged and requires stall testing. No control-layout or mod changes bundled.

Before adoption compare same scene, save, settings, render scale and frame cap against original. Measure touch-to-photon with high-speed camera and frame-time distribution; test startup, resize, background/resume and GPU stalls. Compile success is not runtime acceptance. No claim that Zink alone caused input latency.
