@echo off
setlocal

:: Initial message
echo *****************************************************************************
echo *                                                                           *
echo *   Remember the password and alias name given to the leaf certificate.     *
echo *                                                                           *
echo *****************************************************************************
pause

:: Interactive input for variables
echo Please enter the following details:
set /p ROOT_ALIAS="Root alias: "
set /p INTERMEDIATE_ALIAS="Intermediate alias: "
set /p LEAF_ALIAS="Leaf alias: "
set /p KEYSTORE_PASSWORD="Keystore password: "
set /p VALIDITY_DAYS="Validity days: "

:: Step 1: Generate Root Certificate
echo Generating Root Certificate...
keytool -genkeypair -alias %ROOT_ALIAS% -keyalg RSA -keysize 2048 -validity %VALIDITY_DAYS% -dname "CN=HFTRoot CA, OU=HFT, O=HFT, L=Stuttgart, ST=BadenWurttemberg, C=Germany" -keystore rootCA.jks -storepass %KEYSTORE_PASSWORD% -keypass %KEYSTORE_PASSWORD%
if %ERRORLEVEL% neq 0 echo Failed to generate root certificate. & exit /b %ERRORLEVEL%
keytool -exportcert -alias %ROOT_ALIAS% -keystore rootCA.jks -storepass %KEYSTORE_PASSWORD% -file rootCA.crt
if %ERRORLEVEL% neq 0 echo Failed to export root certificate. & exit /b %ERRORLEVEL%

:: Step 2: Generate Intermediate Certificate
echo Generating Intermediate Certificate...
keytool -genkeypair -alias %INTERMEDIATE_ALIAS% -keyalg RSA -keysize 2048 -validity %VALIDITY_DAYS% -dname "CN=HFTIntermediate CA, OU=HFT, O=HFT, L=Stuttgart, ST=BadenWurttemberg, C=Germany" -keystore intermediateCA.jks -storepass %KEYSTORE_PASSWORD% -keypass %KEYSTORE_PASSWORD%
if %ERRORLEVEL% neq 0 echo Failed to generate intermediate certificate. & exit /b %ERRORLEVEL%
keytool -certreq -alias %INTERMEDIATE_ALIAS% -keystore intermediateCA.jks -storepass %KEYSTORE_PASSWORD% -file intermediateCA.csr
if %ERRORLEVEL% neq 0 echo Failed to generate intermediate CSR. & exit /b %ERRORLEVEL%
keytool -gencert -infile intermediateCA.csr -outfile intermediateCA.crt -keystore rootCA.jks -storepass %KEYSTORE_PASSWORD% -alias %ROOT_ALIAS% -validity %VALIDITY_DAYS% -ext BC=0 -ext KeyUsage=cRLSign,keyCertSign
if %ERRORLEVEL% neq 0 echo Failed to sign intermediate certificate. & exit /b %ERRORLEVEL%

:: Import the intermediate certificate back into its keystore to complete the chain
keytool -importcert -alias %ROOT_ALIAS% -file rootCA.crt -keystore intermediateCA.jks -storepass %KEYSTORE_PASSWORD% -noprompt
if %ERRORLEVEL% neq 0 echo Failed to import root certificate into intermediate keystore. & exit /b %ERRORLEVEL%
keytool -importcert -alias %INTERMEDIATE_ALIAS% -file intermediateCA.crt -keystore intermediateCA.jks -storepass %KEYSTORE_PASSWORD% -noprompt
if %ERRORLEVEL% neq 0 echo Failed to import intermediate certificate into intermediate keystore. & exit /b %ERRORLEVEL%

:: Step 3: Generate Leaf Certificate
echo Generating Leaf Certificate...
keytool -genkeypair -alias %LEAF_ALIAS% -keyalg RSA -keysize 2048 -validity %VALIDITY_DAYS% -dname "CN=HFTLeaf Certificate, OU=HFT, O=HFT, L=Stuttgart, ST=BadenWurttemberg, C=Germany" -keystore leaf.jks -storepass %KEYSTORE_PASSWORD% -keypass %KEYSTORE_PASSWORD%
if %ERRORLEVEL% neq 0 echo Failed to generate leaf certificate. & exit /b %ERRORLEVEL%
keytool -certreq -alias %LEAF_ALIAS% -keystore leaf.jks -storepass %KEYSTORE_PASSWORD% -file leaf.csr
if %ERRORLEVEL% neq 0 echo Failed to generate leaf CSR. & exit /b %ERRORLEVEL%
keytool -gencert -infile leaf.csr -outfile leaf.crt -keystore intermediateCA.jks -storepass %KEYSTORE_PASSWORD% -alias %INTERMEDIATE_ALIAS% -validity %VALIDITY_DAYS% -ext BC=0
if %ERRORLEVEL% neq 0 echo Failed to sign leaf certificate. & exit /b %ERRORLEVEL%

:: Step 4: Import Certificates into Keystores
echo Importing Certificates...
keytool -importcert -alias %ROOT_ALIAS% -file rootCA.crt -keystore leaf.jks -storepass %KEYSTORE_PASSWORD% -noprompt
if %ERRORLEVEL% neq 0 echo Failed to import root certificate into leaf keystore. & exit /b %ERRORLEVEL%
keytool -importcert -alias %INTERMEDIATE_ALIAS% -file intermediateCA.crt -keystore leaf.jks -storepass %KEYSTORE_PASSWORD% -noprompt
if %ERRORLEVEL% neq 0 echo Failed to import intermediate certificate into leaf keystore. & exit /b %ERRORLEVEL%
keytool -importcert -alias %LEAF_ALIAS% -file leaf.crt -keystore leaf.jks -storepass %KEYSTORE_PASSWORD% -noprompt
if %ERRORLEVEL% neq 0 echo Failed to import leaf certificate into leaf keystore. & exit /b %ERRORLEVEL%

:: Step 5: Convert JKS to PKCS12
echo Converting JKS to PKCS12...
keytool -importkeystore -srckeystore leaf.jks -destkeystore leaf.p12 -deststoretype PKCS12 -srcstorepass %KEYSTORE_PASSWORD% -deststorepass %KEYSTORE_PASSWORD%
if %ERRORLEVEL% neq 0 echo Failed to convert JKS to PKCS12. & exit /b %ERRORLEVEL%

:: Step 6: Verify the Certificate Chain
echo Verifying Certificate Chain...
keytool -list -v -keystore leaf.jks -storepass %KEYSTORE_PASSWORD%
if %ERRORLEVEL% neq 0 echo Certificate chain verification failed. & exit /b %ERRORLEVEL%

echo Certificate chain creation and keystore setup completed.
endlocal
pause
