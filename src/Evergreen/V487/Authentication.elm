module Evergreen.V487.Authentication exposing (..)

import Dict
import Evergreen.V487.Credentials
import Evergreen.V487.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V487.User.User
    , credentials : Evergreen.V487.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
