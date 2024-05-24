package org.example;

import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.kernel.pdf.StampingProperties;
import com.itextpdf.signatures.BouncyCastleDigest;
import com.itextpdf.signatures.PdfSignatureAppearance;
import com.itextpdf.signatures.PrivateKeySignature;
import org.bouncycastle.jce.provider.BouncyCastleProvider;


import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.security.Key;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.Security;
import java.security.cert.Certificate;
import com.itextpdf.signatures.PdfSigner;

public class Main {

    public static void main(String[] args) throws Exception {
        String keystorePath = "leaf.p12"; // Path to your keystore file
        String keystorePassword = args[0]; // Password to access the keystore
        String keyAlias = args[1]; // Alias of the key entry in the keystore
        PrivateKey privateKey = null;
        Certificate[] certificateChain = null;
        String srcPdfPath = "input.pdf"; // Input and output PDF files
        String destPdfPath = "output.pdf";

        extractKeyCert keyAndCert = getExtractKeyCert(keystorePath, keystorePassword, keyAlias, privateKey, certificateChain);

        signPdf(srcPdfPath, destPdfPath, keyAndCert.privateKey(), keyAndCert.certificateChain());

    }

    private static extractKeyCert getExtractKeyCert(String keystorePath, String keystorePassword, String keyAlias, PrivateKey privateKey, Certificate[] certificateChain) {
        try {
            // Load the keystore`
            KeyStore keystore = KeyStore.getInstance("PKCS12");
            FileInputStream fis = new FileInputStream(keystorePath);
            keystore.load(fis, keystorePassword.toCharArray());

            Key key = keystore.getKey(keyAlias, keystorePassword.toCharArray()); // Get the private key

            if (key instanceof PrivateKey) {
                privateKey = (PrivateKey) key;
                certificateChain = keystore.getCertificateChain(keyAlias);

            } else {
                System.out.println("No private key found for the alias: " + keyAlias);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        extractKeyCert keyAndCert = new extractKeyCert(privateKey, certificateChain);
        return keyAndCert;
    }




    private record extractKeyCert(PrivateKey privateKey, Certificate[] certificateChain) {
    }

    public static void signPdf(String srcPdfPath, String destPdfPath, PrivateKey privateKey, Certificate[] chain) throws Exception {
        Security.addProvider(new BouncyCastleProvider()); // Initialize BouncyCastleProvider
        PdfReader reader = new PdfReader(srcPdfPath);
        PdfWriter writer = new PdfWriter(destPdfPath);
        PdfSigner signer = new PdfSigner(reader, new FileOutputStream(destPdfPath), new StampingProperties());
        PdfSignatureAppearance appearance = signer.getSignatureAppearance();
        appearance.setReason("Sign PDF");
        appearance.setLocation("Location");
        appearance.setSignatureCreator("Creator");
        appearance.setReuseAppearance(false);
        // Creating the signature
        PrivateKeySignature pks = new PrivateKeySignature(privateKey, "SHA-256", "BC");
        BouncyCastleDigest digest = new BouncyCastleDigest();
        signer.signDetached(digest, pks, chain, null, null, null, 0, PdfSigner.CryptoStandard.CMS);
        System.out.println("PDF signed successfully.");
    }
}
