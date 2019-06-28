#
#  This is a little script to populate Firefox Sync with
#  fake password records.  Use it like so:
#
#    $> pip install PyFxA syncclient cryptography
#    $> python ./upload_fake_passwords.py 20
#
#  It will prompt for your Firefox Account email address and
#  password, generate and upload 20 fake password records, then
#  sync down and print all password records stored in sync.
#    

import os
import time
import json
import random
import string
import getpass
import hmac
import hashlib
import base64
import uuid
from binascii import hexlify

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend

import fxa.core
import fxa.crypto
import syncclient.client


CRYPTO_BACKEND = default_backend()


EMAIL = "firefoxlockbox@gmail.com"
PASSWORD = "aabbcc112233!"


# Here you can customize how fake password records are generated.

def make_fake_password_record():
    print("fake password in function")
    now = int(time.time() * 1000)
    hostname = make_random_hostname()
    return {
        "id": "{%s}" % (uuid.uuid4(),),
        "username": "aaafakeTesterDelete",
        "password": make_random_password(),
        "hostname": hostname,
        "formSubmitURL": hostname,
        "usernameField": "username",
        "passwordField": "password",
        "timeCreated": now,
        "timePasswordChanged": now,
        "httpRealm": None,
    }


def make_random_password():
    print("fake password generate")
    size = random.randint(8, 20)
    return "".join(random.choice(string.ascii_letters + string.digits + string.punctuation) for _ in range(size))


def make_random_hostname():
    print("fake hostname generate")
    size = random.randint(5, 10)
    return ".".join([
        random.choice(["https://www", "http://www", "https://", "https://accounts"]),
        "aaaaa",
        random.choice(["com", "net", "org", "co.uk"])
    ])


# Below here is all the mechanics of uploading them to the sync server.


def main(count=20):
    creds = login()
    upload_fake_password_records(count, *creds)


def login():
    client = fxa.core.Client()
    print ("Signing in as", EMAIL, "...")
    session = client.login(EMAIL, PASSWORD, keys=True)
    try:
        status = session.get_email_status()
        while not status["verified"]:
            print ("Please click through the confirmation email.")
            if input("Hit enter when done, or type 'resend':").strip() == "resend":
                session.resend_email_code()
            status = session.get_email_status()
        assertion = session.get_identity_assertion("https://token.services.mozilla.com/")
        _, kB = session.fetch_keys()
    finally:
        session.destroy_session()
    return assertion, kB


def upload_fake_password_records(count, assertion, kB):
    # Connect to sync.
    print ("in upload")
    xcs = hexlify(hashlib.sha256(kB).digest()[:16])
    client = syncclient.client.SyncClient(assertion, xcs)
    # Fetch /crypto/keys.
    raw_sync_key = fxa.crypto.derive_key(kB, "oldsync", 64)
    root_key_bundle = KeyBundle(
        raw_sync_key[:32],
        raw_sync_key[32:],
    )
    keys_bso = client.get_record("crypto", "keys")
    keys = root_key_bundle.decrypt_bso(keys_bso)
    print ("in upload before if")
    default_key_bundle = KeyBundle(
      base64.b64decode(keys["default"][0]),
      base64.b64decode(keys["default"][1]),
    )
    # Make a lot of password records.
    for i in range(1, count + 1):
        print ("Uploading", i, "of", count, "fake password records...")
        r = make_fake_password_record()
        print("fake password")
        er = default_key_bundle.encrypt_bso(r)
        print("fake password encoded2")
        assert default_key_bundle.decrypt_bso(er) == r
        client.put_record("passwords", er)
    print ("Synced password records:")
    for er in client.get_records("passwords"):
        r = default_key_bundle.decrypt_bso(er)
        # print ("    %s: %r (%s)" % (r["username"].encode('utf-8'), r["password"].encode('utf8'), r["hostname"]))
    print ("Done!")


class KeyBundle:
    """A little helper class to hold a sync key bundle."""

    def __init__(self, enc_key, mac_key):
        self.enc_key = enc_key
        self.mac_key = mac_key

    def decrypt_bso(self, data):
        payload = json.loads(data["payload"])
        print ("in decrypt1")
        mac = hmac.new(self.mac_key, payload["ciphertext"].encode("utf-8"), hashlib.sha256)
        print ("in decrypt2")
        if mac.hexdigest() != payload["hmac"]:
            raise ValueError("hmac mismatch: %r != %r" % (mac.hexdigest(), payload["hmac"]))

        iv = base64.b64decode(payload["IV"])
        cipher = Cipher(
            algorithms.AES(self.enc_key),
            modes.CBC(iv),
            backend=CRYPTO_BACKEND
        )
        decryptor = cipher.decryptor()
        plaintext = decryptor.update(base64.b64decode(payload["ciphertext"]))
        plaintext += decryptor.finalize()

        unpadder = padding.PKCS7(128).unpadder()
        plaintext = unpadder.update(plaintext) + unpadder.finalize()

        return json.loads(plaintext)


    def encrypt_bso(self, data):
        print("In encryp")
        plaintext = json.dumps(data).encode('utf-8')
        
        padder = padding.PKCS7(128).padder()
        plaintext = padder.update(plaintext) + padder.finalize()
        
        print("In encryp bef2")
        
        iv = os.urandom(16)
        cipher = Cipher(
            algorithms.AES(self.enc_key),
            modes.CBC(iv),
            backend=CRYPTO_BACKEND
        )
        print("In encryp2")
        encryptor = cipher.encryptor()
        ciphertext = encryptor.update(plaintext)
        ciphertext += encryptor.finalize()
        print("In encryp3")
        b64_ciphertext = base64.b64encode(ciphertext)
        mac = hmac.new(self.mac_key, b64_ciphertext, hashlib.sha256).hexdigest()
        print("In encryp4")
        print(mac)
        print(base64.b64encode(iv).decode("utf-8"))
        print(b64_ciphertext.decode("utf-8"))
        return {
            "id": data["id"],
            "payload": json.dumps({
                "ciphertext": b64_ciphertext.decode("utf-8"),
                "IV": base64.b64encode(iv).decode("utf-8"),
                "hmac": mac
            })
        }


if __name__ == "__main__":
    import sys
    count = 20
    if len(sys.argv) > 1:
        count = int(sys.argv[1])
    main(count)
