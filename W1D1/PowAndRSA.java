import java.math.BigInteger;
import java.security.*;

public class PowAndRSA {

    /**
     * 题目#1
     * 实践 POW
     */
    public static int pow(String prefix) throws Exception{
        MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
        int i = 0;

        //开始循环
        while (true){

            //获取sha256结果，拼接字符串
            byte[] resb = sha256.digest(("fankun"+ i++).getBytes());
            StringBuilder sb = new StringBuilder();
            for (byte b : resb) {
                sb.append(String.format("%02x",b));
            }
            String res = sb.toString();

            //输出结果
            if(res.startsWith(prefix)){
                System.out.println(res);
                return i-1;
            }
        }



    }

    /**
     * 题目#2
     * 实践非对称加密 RSA
     */
    public static boolean rsa(String data) throws NoSuchAlgorithmException, InvalidKeyException, SignatureException {

        //生成公私钥匙对
        KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA");
        keyGen.initialize(2048);
        KeyPair pair = keyGen.generateKeyPair();
        PrivateKey privateKey = pair.getPrivate();
        PublicKey publicKey = pair.getPublic();

        //私钥签名
        byte[] bytes = data.getBytes();
        Signature sig = Signature.getInstance("SHA256withRSA");

        sig.initSign(privateKey);
        sig.update(bytes);
        byte[] signature = sig.sign();

        //公钥验证
        sig.initVerify(publicKey);
        sig.update(bytes);

        return sig.verify(signature);
    }

    public static void main(String[] args) throws Exception {
        String prefix = "00000";
        long timestamp = System.currentTimeMillis();
        int count = pow(prefix);
        System.out.println(prefix + "前缀，共计算了"+count+"次，耗时"+ (System.currentTimeMillis()-timestamp)/1000);

        boolean rsa = rsa("fankun" + count);
        System.out.println("rsa校验结果："+rsa);
    }


}