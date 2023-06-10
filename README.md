# SEED_Elephant_File

Description of the "SEED Elephant Memory"
Program Many cryptocurrency holders face the challenge of securely storing their SEED phrase. Many of them make one mistake - storing the SEED online (on Google Drive, email, or elsewhere). Even when encrypted in a RAR archive, the SEED is often stolen by cracking such archives through simple brute force. Of course, the issue lies in the relative weakness of the archive password compared to the variability of the SEED itself. The SEED is not susceptible to brute force attacks, at least until the next breakthrough in quantum computers. How many total variations of a 12-word SEED exist? Each word is taken from a vocabulary of 2048 words. This means that the SEED is a 12-digit number in the base-2048 numbering system, which is equivalent to 2048 raised to the power of 12.

Now to the core!
The idea behind this program is to encrypt the SEED with a key that has even greater variability, yet is easier to remember for a person.
Let's take the alphabet as the encryption dictionary. This program supports both English and Russian.
Coding a=0, b=1, c=2, ..., y=24, z=25
The 12-digit number in the base-2048 numbering system
corresponds to 5.4445E+39 in the decimal numbering system, 
which is slightly less than a 29-digit number in the base-26 numbering system
(when we write a number using the characters of the English alphabet)

How it works!
Let's allow the user to come up with any convenient and memorable phrase consisting of at least 27 letters.
For example: "an apple a day keeps the doctor away".
Now let's calculate the number in the base-26 numbering system that corresponds to the user's phrase:
"an apple a day keeps the doctor away" = 
(0, 13, 0, 15, 15, 11, 4, 0, 3, 0, 24, 10, 4, 4, 15, 18, 19, 7, 4, 3, 14, 2, 19, 14, 17, 0, 22, 0, 24)
Next, we convert this number to the base-2048 numbering system. We obtain a shorter number:
(784, 177, 2013, 660, 1106, 139, 1094, 682, 1341, 563, 749, 1728)
Our number has 13 digits, which is sufficient to encode each of our SEED words.
We save the user's SEED to a file, placing each SEED word on a line corresponding to the number from the obtained sequence (784, 177, 2013, 660, 1106, 139, 1094, 682, 1341, 563, 749, 1728)
The first SEED word goes on line number 784,
The second SEED word goes on line number 177,
The third SEED word goes on line number 2013,
...
The twelfth SEED word goes on line number 1728

Now let's take the remaining words from the SEED dictionary. We have 2048 - 12 = 2036 words left. Let's shuffle them randomly and use them to fill the remaining lines of the file. As a result, we will have a file with 2048 lines. It contains all the SEED words from the dictionary, but they are shuffled. Decrypting the SEED is only possible by knowing the positions and order of all 12 words. And brute-forcing such a task is as difficult as searching for the SEED from a regular dictionary. 
We remember that we used a password with variability no less than that of the original SEED.
It is strongly recommended to create such a file on a separate, clean, and offline smartphone to protect against keyboard spies. 
Afterward, you can safely store the file with the shuffled SEED words. You can make a copy on your favorite Google Drive or keep it on your computer. 
I recommend using it as follows: only use this SEED phrase on cold hardware wallets. To enter the hardware wallet, decrypt your SEED by entering the phrase from the chosen file. The SEED will be displayed on the screen. You will be able to reprint SEED on your cold wallet by copying it from the screen of the program on your smartphone.
