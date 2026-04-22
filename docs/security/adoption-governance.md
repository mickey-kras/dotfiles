# Adoption Governance

Future MCP or plugin additions should meet this bar before landing:

1. Official vendor docs or official source repo identified.
2. Registry presence checked, if the server is in the MCP registry.
3. Publisher trust, maintenance health, permission surface, data sensitivity,
   prompt-injection exposure, and blast radius reviewed.
4. Pack placement and profile gating justified explicitly.
5. Constraints documented if the tool is not safe for all machines or all packs.
6. Tests or rendered-output checks updated when the tool changes host output.

Biases that stay in force:

- prefer fewer, stronger servers
- prefer local auditable assets over opaque plugins
- prefer profile gating for high-risk tools
- reject Sentry surfaces
- keep connector-backed plugins out of the managed product surface
