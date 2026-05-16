import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// ERC-4337 EntryPoint v0.7 — deterministic address, same on all chains
const ENTRY_POINT = "0x0000000071727De22E5E9d8BAf0edAc6f37da032";

export default buildModule("VerticalAccountFactoryModule", (m) => {
  const factory = m.contract("VerticalAccountFactory", [ENTRY_POINT]);
  return { factory };
});
