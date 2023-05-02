import React, { useState, useEffect } from 'react';
import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit';
import BigNumber from "bignumber.js";
import celoassist from './abis/celoassist.abi.json';
import erc20 from './abis/irc.abi.json';
import Header from './components/Header';
import RequestLists from './components/RequestLists';


const ERC20_DECIMALS = 18;

// Deployed smart contract address.
const contractAddress = "0xbF3e77C4ab5c82485D2487e170b8457aEb2037F0";

// cUSD contract address contract address.
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";


function App() {

// Declaring variables.
  const [celoBalance, setCeloBalance] = useState(0);
  const [contract, setcontract] = useState(null);
  const [address, setAddress] = useState(null);
  const [kit, setKit] = useState(null);
  const [cUSDBalance, setcUSDBalance] = useState(0);
  const [requests, setRequests] = useState([]);
  const [modal, setModal] = useState(false);
  const [loading, setLoading] = useState(false)
  const toggle = () => setModal(!modal);


// An async function that connects your wallet to the dApp.
  const connectCeloWallet = async () => {
    if (window.celo) {
      try {
        await window.celo.enable();
        const web3 = new Web3(window.celo);
        let kit = newKitFromWeb3(web3);

        const accounts = await kit.web3.eth.getAccounts();
        const user_address = accounts[0];

        kit.defaultAccount = user_address;

        await setAddress(user_address);
        await setKit(kit);

      } catch (error) {
        console.log('There is an error')
        console.log({ error });
      }
    } else {
      console.log("please install the extension");
    }
  };

// useEffect that calls  the connect wallet function each time the page loads.
  useEffect(() => {
    connectCeloWallet();
  }, []);


// useEffect that calls  the get balance function each time the page loads.  
  useEffect(() => {
    if (kit && address) {
      return getBalance();
    } else {
      console.log("no kit or address");
    }
  }, [kit, address]);

  useEffect(() => {
    if (contract) {
      getRequests()
    };
  }, [contract]);


// An async function that gets the balance in your celo wallet.
  const getBalance = async () => {
    setLoading(true)
    const balance = await kit.getTotalBalance(address);
    const celoBalance = balance.CELO.shiftedBy(-ERC20_DECIMALS).toFixed(2);
    const USDBalance = balance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2);

    const contract = new kit.web3.eth.Contract(celoassist, contractAddress);
    setcontract(contract);
    setCeloBalance(celoBalance);
    setcUSDBalance(USDBalance);
    setLoading(false)
  };

  // An async function that retrives all payee requests from the smart contract.
  const getRequests = async function () {
    const requestLength = await contract.methods.getPayeeLength().call();
    const _requests = [];
    for (let index = 0; index < requestLength; index++) {
      let _request = new Promise(async (resolve, reject) => {
        let data = await contract.methods.fetchPayeeById(index).call();
        resolve({
          index: index,
          owner: data[0],
          payeeFullName: data[1],
          payeeDescription: data[2],
          networkType: data[3],
          payeeGasFee: new BigNumber(data[4]),
        })
      });

      _requests.push(_request);
      setModal(false)
    }
    const allRequests = await Promise.all(_requests);
    setRequests(allRequests);
  }

  // An async function that add payee request to the smart contract
  const createRequest = async (_payeeFullName, _payeeDescription, _payeeGasFee, _networkType) => {
    setLoading(true)
    try {
      const payeeGasFee = new BigNumber(_payeeGasFee).shiftedBy(ERC20_DECIMALS).toString();
      await contract.methods
        .createPayee(
          _payeeFullName, _payeeDescription, _networkType, payeeGasFee
        )
        .send({ from: address });
      setLoading(false)
      alert('Request created')
      getRequests();

    } catch (error) {
      alert('Terminated')
    }

  }


  return (

    <div className="content">
    {/* Header component that recieves props */}
      <Header balance={cUSDBalance} celo={celoBalance} modal={modal}
        toggle={toggle} createRequest={createRequest} loading={loading} />

{/* Request List component that recieves props */}
      <RequestLists requests={requests} contract={contract} kit={kit} address={address}
        loading={loading} getBalance={getBalance} getRequests={getRequests}/>
    </div>

  );
}

export default App;
