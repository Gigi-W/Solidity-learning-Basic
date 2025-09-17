// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Sort{
    function insertSort(uint8[] memory arr) public pure returns(uint8[] memory){
        for(uint8 i=1;i<arr.length;i++){
            uint8 current = arr[i];
            uint8 j = i;
            while(j>=1 && current<arr[j-1]){
                arr[j]=arr[j-1];
                j--;
            }
            arr[j]=current;
        }
        return arr;
    }
}