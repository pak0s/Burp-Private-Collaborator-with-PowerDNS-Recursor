#!/bin/bash
# Variables provided by Certbot

DOMAIN="$CERTBOT_DOMAIN"
VALIDATION="$CERTBOT_VALIDATION"
RECORD_NAME="_acme-challenge.${DOMAIN}"

CHALLENGE_ONE="/tmp/challenge1.txt"
CHALLENGE_TWO="/tmp/challenge2.txt"

touch $CHALLENGE_ONE
touch $CHALLENGE_TWO

if [ -s "$CHALLENGE_ONE" ]; then
    echo "\"$VALIDATION\"" > "$CHALLENGE_TWO"
    echo "Adding TXT record $VALIDATION to $CHALLENGE_TWO"
else
    echo "\"$VALIDATION\"" > "$CHALLENGE_ONE"
    echo "Adding TXT record $VALIDATION to $CHALLENGE_ONE"
fi

echo "Added TXT record token for $RECORD_NAME"

chmod 777 $CHALLENGE_ONE
chmod 777 $CHALLENGE_TWO