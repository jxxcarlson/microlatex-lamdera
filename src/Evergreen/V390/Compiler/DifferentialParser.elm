module Evergreen.V390.Compiler.DifferentialParser exposing (..)

import Evergreen.V390.Compiler.AbstractDifferentialParser
import Evergreen.V390.Compiler.Acc
import Evergreen.V390.Parser.Block
import Evergreen.V390.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V390.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V390.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V390.Parser.Block.ExpressionBlock) Evergreen.V390.Compiler.Acc.Accumulator
