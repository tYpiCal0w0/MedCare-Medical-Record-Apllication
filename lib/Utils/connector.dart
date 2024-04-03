import 'package:fluttertoast/fluttertoast.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

class Connector {
  static late EthereumAddress address;
  static late String key;
  static String blockchainUrl =
      "https://sepolia.infura.io/v3/86a80415ed6a4a86b8f06a231015927e";

  static Client httpClient = Client();
  static Web3Client ethClient = Web3Client(blockchainUrl, httpClient);

  static Future<DeployedContract> getContractPatient() async {
    String abiFilePatient =
        await rootBundle.loadString("assets/contracts/patient.json");
    String contractAddress = "0xA48927B1A3c60947CDa47bfe3B2855D4CD688d3a";
    final contractPatient = DeployedContract(
        ContractAbi.fromJson(abiFilePatient, "Patient"),
        EthereumAddress.fromHex(contractAddress));

    return contractPatient;
  }

  static Future<DeployedContract> getContractDoctor() async {
    String abiFileDoctor =
        await rootBundle.loadString("assets/contracts/doctor.json");
    String contractAddress = "0xBD8c957b98689F8bb78C8112c9abfBbff5997868";
    final contractDoctor = DeployedContract(
        ContractAbi.fromJson(abiFileDoctor, "Doctor"),
        EthereumAddress.fromHex(contractAddress));
    return contractDoctor;
  }

  static Future<bool> isDoctorExists(EthereumAddress address) async {
    final contract = await getContractDoctor();
    final result = await ethClient.call(
        contract: contract,
        function: contract.function("isDoctor"),
        params: [address]);
    return result[0];
  }

  static Future<bool> isPatientExists(EthereumAddress address) async {
    final contract = await getContractPatient();
    final result = await ethClient.call(
        contract: contract,
        function: contract.function("isPatient"),
        params: [address]);
    return result[0];
  }

  static Future<String> getFee(EthereumAddress address) async {
    final contract = await getContractDoctor();
    final result = await ethClient.call(
        contract: contract,
        function: contract.function("getFee"),
        params: [address]);
    return result[0].toString();
  }

  static Future<bool> isAuthorized(
      EthereumAddress doc, EthereumAddress pat) async {
    final contract = await getContractPatient();
    final result = await ethClient.call(
        contract: contract,
        function: contract.function("isAuthorized"),
        params: [doc, pat]);
    return result[0];
  }

  static Future<dynamic> getPresc(EthereumAddress address) async {
    final contract = await getContractPatient();
    final result = await ethClient.call(
        contract: contract,
        function: contract.function("viewPrescription"),
        params: [address]);
    return result[0];
  }

  static Future<bool> logInDoctor(String address, String privateKey) async {
    EthereumAddress addr = EthereumAddress.fromHex(address);
    bool result = await isDoctorExists(addr);
    if (result == true) return true;
    Credentials key = EthPrivateKey.fromHex(privateKey);

    //obtain our contract from abi in json file
    final contract = await getContractDoctor();

    // extract function from json file
    final function = contract.function("addDoctor");

    //send transaction using the our private key, function and contract
    await ethClient.sendTransaction(
      key,
      Transaction.callContract(
          contract: contract, function: function, parameters: [addr]),
      chainId: 11155111,
    );
    //set a 40 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    await Future.delayed(const Duration(seconds: 40), () {});
    result = await isDoctorExists(addr);
    return result;
  }

  static Future<bool> logInPatient(String address, String privateKey) async {
    // print("here2");
    EthereumAddress addr = EthereumAddress.fromHex(address);
    bool result = await isPatientExists(addr);
    // print("here3");
    if (result == true) return true;
    Credentials key = EthPrivateKey.fromHex(privateKey);
    // print("here4");
    //obtain our contract from abi in json file
    final contract = await getContractPatient();

    // extract function from json file
    final function = contract.function("addPatient");

    //send transaction using the our private key, function and contract
    await ethClient.sendTransaction(
      key,
      Transaction.callContract(
          contract: contract, function: function, parameters: [addr]),
      chainId: 11155111,
    );
    //set a 40 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    await Future.delayed(const Duration(seconds: 40), () {});
    result = await isPatientExists(addr);
    return result;
  }

  static Future<String> updateDoctorFee(
      EthereumAddress address, String privateKey, String amount) async {
    Credentials key = EthPrivateKey.fromHex(privateKey);

    //obtain our contract from abi in json file
    final contract = await getContractDoctor();

    // extract function from json file
    final function = contract.function("updateFee");

    //send transaction using the our private key, function and contract
    // print("here2");
    await ethClient.sendTransaction(
        key,
        Transaction.callContract(
            contract: contract,
            function: function,
            parameters: [address, BigInt.parse(amount)]),
        chainId: 11155111);
    // print("here3");
    //set a 40 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    await Future.delayed(const Duration(seconds: 40), () {});
    // print("here4");
    String result = await getFee(address);
    return result;
  }

  static Future<bool> addAuthorization(
      EthereumAddress doc, EthereumAddress pat, String privateKey) async {
    bool result = await isAuthorized(doc, pat);
    if (result) return true;
    String fee = await getFee(doc);

    Credentials key = EthPrivateKey.fromHex(privateKey);

    //obtain our contract from abi in json file
    final contract = await getContractPatient();

    // extract function from json file
    final function = contract.function("addAuthorization");

    //send transaction using the our private key, function and contract
    await ethClient.sendTransaction(
        key,
        Transaction.callContract(
            value: EtherAmount.fromUnitAndValue(EtherUnit.wei, fee),
            contract: contract,
            function: function,
            parameters: [doc, pat, BigInt.parse(fee)]),
        chainId: 11155111);
    //set a 40 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    await Future.delayed(const Duration(seconds: 40), () {});
    result = await isAuthorized(doc, pat);
    return result;
  }

  static Future<void> setPresc(EthereumAddress doc, EthereumAddress pat,
      String privateKey, String prescription) async {
    if (await isAuthorized(doc, pat)) {
      Credentials key = EthPrivateKey.fromHex(privateKey);

      //obtain our contract from abi in json file
      final contract = await getContractPatient();

      // extract function from json file
      final function = contract.function("setPrescription");

      //send transaction using the our private key, function and contract
      await ethClient.sendTransaction(
          key,
          Transaction.callContract(
              contract: contract,
              function: function,
              parameters: [prescription, pat, doc]),
          chainId: 11155111);
    } else {
      Fluttertoast.showToast(msg: "You are not authorized");
    }
  }
}
