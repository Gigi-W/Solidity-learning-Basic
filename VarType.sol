// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Parent{
    // 基本类型5个，整型、布尔、地址、固定大小字节、枚举
    string public constant str1 = "Hello Gigi";
    uint8 private _number = 10;
    bytes1 internal _byte1 = 'a';
    bytes1 internal _byte3 = 0x01;
    address public owner = 0x742d35Cc6634C0532925a3b844Bc454e4438f44e;

    enum Type1{Color,Food}
    Type1 public type1 = Type1.Color;

    enum Type2{Fruit, Veg}
    Type2 public type2 = Type2.Fruit;

    // bool public judgeEqual = type1==type2; // 枚举不能直接比较，会报错


    bool public immutable _bool1=true;
    constructor(){
        _bool1 = false;
    }

    // 复杂类型，数组（固定长度、可变长度、bytes（可变长度二进制，编码解码））、结构体
    uint8[3] private arr1=[1,2,3];
    uint8[] private arr2;
    function initArr() private{
        arr2=[1,2,3,4];
        uint8[] memory arr3 = new uint8[](5);
        arr3[0]=1;
    }

    struct Person{
        string name;
        uint8 age;
    }

    Person public person1 = Person('Gigi', 29);
    Person public person2 = Person({name: 'Gigi1',age:30});
    Person public person3;
    function initPerson() public{
        person3.name='Gigi3';
        person3.age=31;
    }



    // 映射
    mapping(uint8=>address) public map1;
    mapping(string=>string) public map2;

    function writeMap() public{
        map1[1]=0x742d35Cc6634C0532925a3b844Bc454e4438f44e;
        map1[2]=address(this);
        map2['a']='hhh';
    }
}
contract Child is Parent{
    string private _str2  = str1;
    bytes1 private _byte2 = _byte1;
}