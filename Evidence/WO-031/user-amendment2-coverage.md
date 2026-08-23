# WO-031 Amendment 2 user coverage clarification

- Recorded: 2026-08-23

During the Amendment 2 device run, the user:

- walked around Seyda Neen and took screenshots when the distant rendering and blocky foliage were visible;
- did not deliberately cast a fire spell;
- observed visible chimney smoke, which was also blocky.

Orchestrator interpretation:

- lack of a cast fire-spell reproduction is a coverage limit, not a diagnostic failure;
- visible chimney smoke is the qualified representative particle symptom for the next targeted R1 capture;
- fire textures appearing in the diagnostic file prove loading/binding candidates, not that a cast-fire draw was visibly exercised;
- WO32 therefore requires foliage plus chimney smoke and treats fire-spell casting as optional.
