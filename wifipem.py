#!/usr/bin/python3

import argparse
import pyshark
import binascii

## Settings
__version__ = '2.0'
certificate_prefix = 'cert'

parser = argparse.ArgumentParser(description='Automated tool to extract the public key presented by WPA2-Enterprise wireless networks')

parser.add_argument('--version', action='version', version=__version__)
parser.add_argument('-o', '--output', dest='output_prefix', default=certificate_prefix, help='filename prefix of the .der output (default: {})'.format(certificate_prefix))
parser.add_argument('-i', '--input', dest='input_filename', help='.pcap file to be extracted')

args, leftover = parser.parse_known_args()
options = args.__dict__

def pcapExtraction(input_filename: str, output_prefix: str):
    packets = pyshark.FileCapture(input_filename)
    certificates = []
    count = 1
    for pkt in packets:
        if 'EAP' in pkt \
        and int(pkt['EAP'].code) == 1 \
        and hasattr(pkt['EAP'], 'tls_handshake_certificate'):
            print('[-]  certificate frame found!')
        else:
            continue

        for cert in pkt['EAP'].tls_handshake_certificate.all_fields:
            certificates.append(cert)
            hex_array = [
                cert.raw_value[i:i+2]
                for i in range(0, len(cert.raw_value), 2)
            ]
            file = '{}-{}-{}-{}.der'.format(
                output_prefix,
                ".".join(
                    input_filename.split('/')[-1].split('.')[:-1]
                ),
                pkt['WLAN'].ta,
                count
            )
            print('[-]  extracting certificate to file: {}'.format(file))
            with open(file, 'wb') as f:
                for ha in hex_array:
                    f.write(binascii.unhexlify(ha))
            print('[-]  open file with the following command:\r\n[-]    openssl x509 -inform der -in {} -text'.format(file))
            count += 1
    return 0

if __name__ == '__main__':
    if(options['input_filename'] is None):
        print('[!] Select one file for extraction')
        exit(0)

    print('[+] Searching for RADIUS public certificate in file: {}'.format(options['input_filename']))
    pcapExtraction(
        input_filename=options['input_filename'],
        output_prefix=options['output_prefix']
    )
    exit(0)
