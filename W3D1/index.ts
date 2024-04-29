import { createPublicClient, http, parseAbiItem } from 'viem';
import { mainnet } from 'viem/chains';


async function main() {

  console.log(process.env.RPC_URL);

  const client = createPublicClient({
    chain: mainnet,
    transport: http(process.env.RPC_URL),
  });

  const blockNumber = await client.getBlockNumber();
  console.log("blockNumber", blockNumber);


  const filter = await client.createEventFilter({
    address: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'),
    fromBlock: blockNumber - 100n,
    toBlock: blockNumber,
  });

  const logs = await client.getFilterLogs({ filter })
  logs.forEach((log) => {
    if (log.args.value) {
      console.log(
        `从 ${log.args.from} 转出到 ${log.args.to} ${Number(log.args.value) / 10 ** 6} USDC , 交易ID: ${log.transactionHash}`
      );
    }
  });


}
main();
