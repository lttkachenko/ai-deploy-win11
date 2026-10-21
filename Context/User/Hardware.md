## 📌 Context & Environment Rules & Limits
This document establishes current [[User-EN]] | [[User-RU]] LLM inference and runtime environment hardware and software, and thus limits, technical decisions and rules concluded by the current hardware.
Also, the desired future hardware configuration is described in the separate section for further system development reference.

### Current Hardware

Current hardware should be considered as temporary legacy configuration targeted to establish stable and usable AI setup for AI Agentic Coding principals, techniques and patterns learning and work-out. Initial production development should be also possible on it. Also in the current circumstances (safety and mobility concerns) stationary server or desktop inference rig are not considered possible or appropriate for the situation. So the hardware configuration is considered as a strong and robust enough laptop setup.

- **Laptop:** GIGABYTE Aorus 15X ASF
  - **CPU:** Intel Core i9 13900HX (slightly degraded by E-Cores and their E-Ring Bus, but stabilized by custom cooling and frequencies lock by 5.0 / 4.0 GHz formula)
  - **GPU:** NVIDIA RTX 4070M (8GB VRAM, 6GB available by CUDA limits in system env vars to save Windows GUI from crash on VRAM out: all the laptop's external ports are powered-up from DGPU directly, there is no possibility to put it on IGPU 100%)
  - **RAM:** 64GB DDR5-5600 CL37 (2 x 32GB Kingston HyperX Fury Impact)
  - **SSD:** 4TB NVME PCIE-4 (2 x 2TB Kingston HyperX Fury Renegade): no RAID0 on Aorus in this series (damn on you GIGABYTE marketoids!)
- **OS / Environment:**
  - **OS:** Windows 11 Pro 64Bit 26H2 (host & inference environment for direct GPU access)
  - **VTS:** WSL 2.X with Ubuntu 26.04.1-LTS (projects & Docker runtime environment and also runtime environment for Aider as AI AQA)
### Future / Desired Hardware

Future hardware is considered as the main production workstation with full enterprise development capabilities.  Safety and mobility concerns are still among the main priorities. So the laptop is still a must for the user.

- **Laptop:** ASUS ROG Strix SCAR 16 (G635LX)
  - **CPU:** Intel Core Ultra 9 275HX
  - **GPU:** NVIDIA RTX 5090M (24GB VRAM, 24GB available: all the laptop's external ports are powered-up from IGPU directly, 100% Windows GUI on IGPU are possible)
  - **RAM:** 64GB DDR5-5600 CL37 (2 x 32GB Kingston HyperX Fury Impact) - should be taken from the previous Aorus setup (switched to Strix stock RAM)
  - **SSD:** 4TB NVME PCIE-4 (2 x 2TB Kingston HyperX Fury Renegade) in RAID0 (Strix has it on BIOS level OOB) - should be taken from the previous Aorus setup (switched to Strix stock SSDs)
- **OS / Environment:**
  - **OS:** Windows 11 Pro 64Bit 26H2 (host & inference environment for direct GPU access)
  - VTS: WSL 2.X with Ubuntu 26.04.1-LTS (projects & Docker runtime environment and also runtime environment for Aider as AI AQA)
