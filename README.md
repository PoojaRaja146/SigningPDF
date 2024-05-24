To run the code use the following command in command prompt


**Note:**
Please Don't change the arguments as the first argument is the password to the keystore and the second argument is the leaf certificate alias name.

Incase it has to be changed please delete the existing certificates and run the certificate_generation.bat file (can be found within the project)

```
./gradlew run --args='linuxpwd123 hftleaf'  

```

Signed Output PDF name - Output.pdf