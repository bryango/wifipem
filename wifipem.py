#!/usr/bin/python3

import argparse

## Settings
__version__ = '2.0'
radius_certificate_extract_location = 'radius.der'
default_timeout = 15

parser = argparse.ArgumentParser(description='Automated tool for extract the public key presented by WPA2-Enterprise wireless networks')

parser.add_argument('--version', action='version', version=__version__)
parser.add_argument('-o', '--output', dest='output_file', default=radius_certificate_extract_location, help='Specify the output file (Default: {})'.format(radius_certificate_extract_location))

sourceOptions = parser.add_argument_group(description='Specify target source for extraction')
sourceOptions.add_argument('-f', '--filename', dest='filename', help='extract .pem from a pcap')

args, leftover = parser.parse_known_args()
options = args.__dict__

def pcapExtraction(filename: str, output_file):
    import pyshark
    import binascii
    packets = pyshark.FileCapture(filename)
    count = 1
    certificates = []
    for pkt in packets:
        if(('EAP' in pkt)):
            if((int(pkt['EAP'].code) == 1) and (hasattr(pkt['EAP'], 'tls_handshake_certificate'))):
                print('[-]  certificate frame found!')
                for cert in pkt['EAP'].tls_handshake_certificate.all_fields:
                    certificates.append(cert)
                    hex_array = [
                        cert.raw_value[i:i+2]
                        for i in range(0, len(cert.raw_value), 2)
                    ]
                    file = '{}-{}-{}.pem'.format(filename.split('.')[0], pkt['WLAN'].ta, count)
                    print('[-]  extracting certificate to file: {}'.format(file))
                    with open(file, 'wb') as f:
                        for ha in hex_array:
                            f.write(
                                binascii.unhexlify(ha)
                            )
                        f.close()
                    print('[-]  open file with the following command:\r\n[-]    openssl x509 -inform der -in {} -text'.format(file))
                    count += 1
    return 0

if __name__ == '__main__':
    if(options['filename'] is None):
        print('[!] Select one file for extraction')
        exit(0)

    print('[+] Searching for RADIUS public certificate in file: {}'.format(options['filename']))
    pcapExtraction(
        filename=options['filename'],
        output_file=options['output_file']
    )
    exit(0)
