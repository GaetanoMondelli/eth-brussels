import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract, zeroPadValue } from "ethers";
import { Options } from "@layerzerolabs/lz-v2-utilities";

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network sepolia`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const flareTestnetEid = 40294;
  const sepoliaEid = 40161;
  const polygonEid = 30109;
  const deplolyedFlarePeer = "0x314773c7C42587d72801A47687CebD789b8BC363";
  const deplolyedSepoliaPeer = "0x4EBB6b3Cf77d8d04645b1EE78CB11A399AC9c8c1";

  // const _options = Options.newOptions();
  const GAS_LIMIT = 1000000; // Gas limit for the executor
  const MSG_VALUE = 0;
  // const _options = Options.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, MSG_VALUE);
  const _options = Options.newOptions().addExecutorLzReceiveOption(200000, 0);
  console.log("options", _options.toHex(), deployer);

  if (hre.network.name === "coston2") {
    console.log("📡 Deploying FtsoV2FeedConsumer to the network conston2 as deployer...");
    const layerZeroEndpointFlareTestnet = "0x6EDCE65403992e310A62460808c4b910D972f10f";
    const bytes32Peer = zeroPadValue(deplolyedFlarePeer, 32);
    await deploy("FtsoV2FeedConsumerLz", {
      from: deployer,
      // Contract constructor arguments
      args: [layerZeroEndpointFlareTestnet, deployer],
      log: true,
      // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    });


    await deploy("IndexGeneratorV2", {
      from: deployer,
      // Contract constructor arguments
      args: [],
      log: true,
      // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    });

    console.log("📡 Deploying IndexGeneratorV2 to the network conston2 as deployer...");

    return;

    await deploy("FtsoV2FeedConsumer", {
      from: deployer,
      // Contract constructor arguments
      args: [],
      log: true,
      // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    });

    const ftsoV2FeedConsumer = await hre.ethers.getContract<Contract>("FtsoV2FeedConsumer", deployer);
    console.log(
      "👋 Initial prices:",
      await ftsoV2FeedConsumer.getFtsoV2CurrentFeedValuesByNames([
        "BTC",
        "XRP",
        "BNB",
        "SOL",
        "XRP",
        "DOGE",
        "AVAX",
        "MATIC",
        "LTC",
        "UNI",
      ]),
    );
    return;
    // Get the deployed contract to interact with it after deploying.
    const ftsoV2FeedConsumerFlare = await hre.ethers.getContract<Contract>("FtsoV2FeedConsumerLz", deployer);
    console.log("👋 Initial prices:", await ftsoV2FeedConsumerFlare.getFtsoV2CurrentFeedValues());

    // await ftsoV2FeedConsumerFlare.setPeer(flareTestnetEid, bytes32Peer);
    console.log("Check the peer", await ftsoV2FeedConsumerFlare.peers(flareTestnetEid));
    // const quote = await ftsoV2FeedConsumerFlare.quote(
    //   flareTestnetEid,
    //   "first message from gaetano",
    //   _options.toHex(),
    //   false,
    // );
    // console.log("quote", quote);
    // console.log("First message ", await ftsoV2FeedConsumerFlare.data());
  }

  if (hre.network.name === "sepolia") {
    console.log("📡 Deploying YourContract to the network sepolia as deployer...");
    const layerZeroEndpointSepolia = "0x6EDCE65403992e310A62460808c4b910D972f10f";
    await deploy("MyOApp", {
      from: deployer,
      // Contract constructor arguments
      // gasLimit: 8000000,
      args: [layerZeroEndpointSepolia],
      log: true,
    });

    const lzSepolia = await hre.ethers.getContract<Contract>("MyOApp", deployer);
    const bytes32Peer = zeroPadValue(deplolyedFlarePeer, 32);
    await lzSepolia.setPeer(flareTestnetEid, bytes32Peer);

    console.log("Check the peer", await lzSepolia.peers(flareTestnetEid));

    const quote = await lzSepolia.quote(flareTestnetEid, "hello", _options.toHex().toString(), false);
    console.log("quote", quote);
  }
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["FtsoV2FeedConsumerLz"];
