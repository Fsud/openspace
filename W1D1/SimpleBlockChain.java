import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

/**
 * 区块结构
 */
class Block {
    public Integer index;

    public Long timestamp;

    public List<Transaction> transactions;

    public Long proof;

    public String previousHash;

    @Override
    public String toString() {
        return "Block{" +
                "index=" + index +
                ", timestamp=" + timestamp +
                ", transactions=" + transactions +
                ", proof=" + proof +
                ", previousHash='" + previousHash + '\'' +
                '}';
    }
}

/**
 * 交易结构
 */
class Transaction{
    public String sender;

    public String recipient;

    public Long amount;

    @Override
    public String toString() {
        return "Transaction{" +
                "sender='" + sender + '\'' +
                ", recipient='" + recipient + '\'' +
                ", amount=" + amount +
                '}';
    }
}

/**
 * 主类，包含区块链结构，newBlock函数，newTransaction函数
 */
public class SimpleBlockChain {

    /**
     * 历史区块
     */
    public List<Block> blocks;

    /**
     * 当前尚未打包的交易
     */
    public List<Transaction> currentTransactions = new ArrayList<>();

    /**
     * 区块链的构造函数，创建一个创世区块
     */
    public SimpleBlockChain(){
        blocks = new LinkedList<>();
        Block originBlock = new Block();
        originBlock.timestamp = System.currentTimeMillis();
        originBlock.index=0;
        originBlock.proof=0L;
        originBlock.previousHash = "";
        blocks.add(originBlock);
    }

    /**
     * 创建区块
     */
    public void newBlock() throws Exception {
        Block lastBlock = blocks.get(blocks.size() - 1);

        int index = lastBlock.index + 1;
        String lastBlockHash = getBlockHash(lastBlock);

        //pow挖矿，获取proof
        Long proof = pow(lastBlockHash);

        //构造新区块
        Block block = new Block();
        block.index = index;
        block.previousHash = lastBlockHash;
        block.proof = proof;
        block.timestamp = System.currentTimeMillis();
        block.transactions = currentTransactions;

        blocks.add(block);
        System.out.println("区块创建成功:"+ block.toString());

        //清空尚未打包的交易
        currentTransactions.clear();

    }

    /**
     * 添加新交易
     */
    public void newTransaction(Transaction transaction){
        currentTransactions.add(transaction);
    }

    /**
     * 计算区块hash
     */
    private String getBlockHash(Block block) throws NoSuchAlgorithmException {
        MessageDigest sha256 = MessageDigest.getInstance("SHA-256");


        byte[] digest = sha256.digest(new StringBuilder()
                .append(block.index)
                .append(block.previousHash)
                .append(String.valueOf(block.transactions))
                .append(block.index)
                .append(block.proof).toString().getBytes());

        StringBuilder sb = new StringBuilder();
        for (byte b : digest) {
            sb.append(String.format("%02x",b));
        }
        return sb.toString();
    }

    /**
     * 进行pow运算
     */
    public static Long pow(String blockHash) throws Exception{
        MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
        Long i = 0L;

        //开始循环
        while (true){

            //获取sha256结果，拼接字符串
            byte[] resb = sha256.digest((blockHash+ i++).getBytes());
            StringBuilder sb = new StringBuilder();
            for (byte b : resb) {
                sb.append(String.format("%02x",b));
            }
            String res = sb.toString();

            //输出结果
            if(res.startsWith("0000")){
                System.out.println(res);
                return i-1;
            }
        }



    }

    public static void main(String[] args) throws Exception {
        SimpleBlockChain simpleBlockChain = new SimpleBlockChain();
        simpleBlockChain.newBlock();

        Transaction transaction = new Transaction();
        transaction.sender = "0xaa";
        transaction.recipient = "0xbb";
        transaction.amount = 1L;
        simpleBlockChain.newTransaction(transaction);
        simpleBlockChain.newBlock();
    }

}



