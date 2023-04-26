const { expect } = require("chai");

describe("wallet", function () {

  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addr4;
  let addr5;
  let WalletFactory;
  let NFTFactory;
  let NFTContract;
  let Wallet;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    WalletFactory = await ethers.getContractFactory("Wallet");
    NFTFactory = await ethers.getContractFactory("MyNFT");
    [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();

    Wallet = await WalletFactory.deploy([owner.address, addr1.address, addr2.address, addr3.address, addr4.address], 3);
    NFTContract = await NFTFactory.deploy();

    await Wallet.deployed();
    await NFTContract.deployed();

    await NFTContract.mint();
    await NFTContract.transferFrom(owner.address, Wallet.address, 1);
  });

  describe("Deployment", async function () {

    
    it("Should set the right owner", async function () {
      expect(await NFTContract.ownerOf(1)).to.equal(Wallet.address);
    });

  });

  describe("Transactions", function () {
    it("Should not request the transactions because of not owner", async function () {
      await expect(
          Wallet.connect(addr5).transactionRequest(addr5.address, NFTContract.address, 1)
      ).to.be.revertedWith("Not owner");
    });

    it("Should not request because of invalid NFT detail", async function () {
      await expect(
          Wallet.transactionRequest(addr3.address, NFTContract.address, 3)
      ).to.be.revertedWith("invalid token ID");
    });

    it("Should not approve because of duplication", async function () {
      await Wallet.transactionRequest(addr5.address, NFTContract.address, 1)
      await Wallet.transactionApproval(0);
      await expect(
        Wallet.transactionApproval(0)
      ).to.be.revertedWith("You already signed this transaction");
    });

    it("Should approve the transactions", async function () {
      await Wallet.transactionRequest(addr5.address, NFTContract.address, 1)
      await Wallet.transactionApproval(0);
    });

    it("Should not approve the transaction because it's already approved", async function () {
      await Wallet.transactionRequest(addr5.address, NFTContract.address, 1)
      await Wallet.transactionApproval(0);
      await Wallet.connect(addr1).transactionApproval(0);
      await Wallet.connect(addr2).transactionApproval(0);

      await expect(
        Wallet.connect(addr3).transactionApproval(0)
      ).to.be.revertedWith("Transaction already approved");
    });

    it("Should approve and proceed the transaction", async function () {
      await Wallet.transactionRequest(addr5.address, NFTContract.address, 1)
      await Wallet.transactionApproval(0);
      await Wallet.connect(addr1).transactionApproval(0);
      await Wallet.connect(addr2).transactionApproval(0);

      const NFTOwner = await NFTContract.ownerOf(1);
      expect(NFTOwner).to.equal(addr5.address);
    });

  });
});
