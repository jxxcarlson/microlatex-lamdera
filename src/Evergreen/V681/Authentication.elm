module Evergreen.V681.Authentication exposing (..)

import Dict
import Evergreen.V681.Credentials
import Evergreen.V681.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V681.User.User
    , credentials : Evergreen.V681.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
