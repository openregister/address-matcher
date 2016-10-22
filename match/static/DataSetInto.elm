module DataSetInfo exposing (DataSetInfo)

type alias DataSetInfoId =
    Int


type alias DataSetName =
    String


type alias DataSetRecord =
    { name : String }



type alias RemoteDataSetInfo =
    WebData (List DataSet)
