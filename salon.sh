#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\nGeneric Salon\n"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo -e "\nWhat service can we schedule you for today?"

  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services;")
  echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  echo -e "\nPlease select a service: "
  read SERVICE_ID_SELECTED

  if [[ -z $SERVICE_ID_SELECTED ]]
  then
    MAIN_MENU "Please enter a service to schedule."
  else
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      MAIN_MENU "Please enter a numerical value."
    else
      SERVICE_ID=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
      if [[ -z $SERVICE_ID ]]
      then
        MAIN_MENU "Invalid service selection."
      else
        SCHEDULE_SERVICE
      fi
    fi
  fi
}

SCHEDULE_SERVICE() {
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID;")
  echo -e "\nYou have selected to schedule a hair $(echo "$SERVICE_NAME" | sed -r 's/^ *| *$//g').\nPlease enter your phone number:"
  read CUSTOMER_PHONE
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  if [[ -z $CUSTOMER_ID ]]
  then
    echo -e "\nYou have not been here before.\nPlease enter your name:"
    read CUSTOMER_NAME
    NEW_CUSTOMER_ID_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE','$CUSTOMER_NAME');")
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
    if [[ -z $CUSTOMER_ID ]]
    then
      MAIN_MENU "We could not create your account right now."
    else
      echo -e "\nThank you, $CUSTOMER_NAME. You are now in the system."
    fi
  else
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
    CUSTOMER_PHONE=$($PSQL "SELECT phone FROM customers WHERE customer_id = $CUSTOMER_PHONE;")
    echo -e "\nWelcome back, $(echo "$CUSTOMER_NAME" | sed -r 's/^ *| *$//g')!"
  fi

  echo -e "\nWhat time would you like to schedule?"
  read SERVICE_TIME

  NEW_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME');")

  echo -e "\nI have put you down for a $(echo "$SERVICE_NAME" | sed -r 's/^ *| *$//g') at $SERVICE_TIME, $(echo "$CUSTOMER_NAME" | sed -r 's/^ *| *$//g')."
}

MAIN_MENU