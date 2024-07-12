import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const sepoliaPoolManager = "0xFf34e285F8ED393E366046153e3C16484A4dD674";

  if (hre.network.name === "sepolia") {
    await deploy("MyHook", {
      from: deployer,
      // Contract constructor arguments
      args: [sepoliaPoolManager],
      log: true,
    });
  }
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["Hook"];
