import UIKit
import CryptoSwift

let testString = """
Put on what weary negligence you please,
You and your fellows. I'd have it come to question.
If he distaste it, let him to our sister,
Whose mind and mine I know in that are one, 520
Not to be overrul'd. Idle old man,
That still would manage those authorities
That he hath given away! Now, by my life,
Old fools are babes again, and must be us'd
With checks as flatteries, when they are seen abus'd. 525
Remember what I have said.
"""

print(testString)

let aes = try? AES(key: "afiretobekindled", iv: "hdjajshdhxdgeehf")

let encryptedString = try? aes!.encrypt(Array(testString.utf8))

print("AES encrypted: \(String(describing: encryptedString))")

let tryagain = encryptedString?.toHexString()

print(String(tryagain!))


// this is sent to a qr code and scanned
print("scanning qr...")

let okthen = Array<UInt8>(hex: tryagain!)

print("AES encrypted: \(String(describing: okthen))")

let decryptedString = try? aes?.decrypt(encryptedString!)

let decrypted = String(bytes: decryptedString!, encoding: .utf8)

print(decrypted!)


