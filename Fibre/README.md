# INSTALLATION 
- Brancher l'ONU dans le port SFP du routeur

# CONFIGURATION
- Se connecter en ssh
```
ssh -o KexAlgorithms=diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-dss  192.168.1.10 -l ONTUSER
```
- Par defaut le login est ONTUSER et le mot de passe est 7sp!lwUBz1
- Modifier le serial
```
set_serial_number ABCD12345678
```
- Modifier le vendor_ID
```
sfp_i2c -i 7 -s “ABCD” 
```
- Brancher la fibre
- Redémarer l'ONU
```
reboot
```
- Attendre deux minute avant de se reconnecter
- Se reconnecter et faire
```
onu ploamsg
```
- On constate, que l’ONU voit son “curr_state” passer 5. L’ONU est désormais reconnu par l’ONT Orange.