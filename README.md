lethe-cfd-case-air-particles/

├── README.md                          # Project description
├── Dockerfile                         # Build the Lethe CFD image
├── docker-compose.yml                 # Docker deployment configuration (for use with Portainer)
├── config/
         ├── simulation.prm                   # Lethe CFD configuration file (your optimized configuration)
         └── mesh.vtk                         # Mesh file (e.g., rbf_sdf_field.vtk)
├── scripts/
         ├── analyze_particles.py             # Particle capture efficiency analysis script
         └── visualize.py                     # Visualization screenshot script
├── output/                            # Simulation result output directory (mountable)
         └── .gitignore                       # Ignore unnecessary files
