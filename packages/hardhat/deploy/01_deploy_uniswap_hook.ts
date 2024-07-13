import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { zeroPadValue, toBeHex } from "ethers";
import { UniswapHooksFactory } from "../typechain-types";

function _doesAddressStartWith(_address: any, _prefix: any) {
  // console.log(_address.substring(0, 4), ethers.toBeHex(_prefix).toString());
  return _address.substring(0, 4) == toBeHex(_prefix).toString();
}

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
    await deploy("PoolManager", {
      from: deployer,
      args: [500000],
      log: true,
    });

    const poolManager = await hre.ethers.getContract("PoolManager", deployer);

    const poolManagerAddress = await poolManager.getAddress();

    await deploy("UniswapInteract", {
      from: deployer,
      args: args,
      log: true,
    });

    // const uniswapInteract = await hre.ethers.getContract("UniswapInteract", deployer);

    await deploy("UniswapHooksFactory", {
      from: deployer,
      args: [poolManagerAddress],
      log: true,
    });

    const hookFactory = await hre.ethers.getContract<UniswapHooksFactory>("UniswapHooksFactory", deployer);

    let salt;
    //The final address is the one that matches the correct prefix
    let finalAddress;
    //The desired prefix is set here
    const correctPrefix = 0xff;

    for (let i = 0; i < 2000; i++) {
      salt = toBeHex(i);
      //console.log(salt);
      salt = zeroPadValue(salt, 32);

      let expectedAddress = await hookFactory.getPrecomputedHookAddress(deployer, poolManagerAddress, salt);
      finalAddress = expectedAddress;
      //console.log(i, "Address:", expectedAddress);
      expectedAddress = expectedAddress;
      //This console.log() prints all of the generated addresses
      console.log(finalAddress);
      if (_doesAddressStartWith(expectedAddress, correctPrefix)) {
        console.log("This is the correct salt:", salt);
        break;
      }
    }

    await hookFactory.deploy(poolManagerAddress, salt as any);
    console.log("Hooks deployed with address:", finalAddress);

    await deploy("MyHook", {
      from: deployer,
      // Contract constructor arguments
      args: [sepoliaPoolManager],
      log: true,
    });
  }
};

export default deployYourContract;

deployYourContract.tags = ["uniswap-hooks"];
