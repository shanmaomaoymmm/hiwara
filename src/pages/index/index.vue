<template>
  <view>
    Hello
  </view>
</template>
<script>
import { getAccessToken } from '@/api/api';
export default{
  data(){
    return{

    }
  },
  created(){
    getAccessToken((res)=>{
      if(res==true){
      
      }
    })
  }
}
</script>