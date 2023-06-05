<template>
  <view>
    <view v-if="onload" style="text-align: center;padding-top: 30vh;">
      <image class="loading" src="@/static/icon/loading.png"></image>
      <br>
      <text>{{ $t('loading1') }}</text>
    </view>
    <view v-else class="comments">
      <view style="padding-bottom: 4rem;">
        <view v-if="data.length == 0" style="text-align: center;padding-top: 30vh;" dir="auto">
          <image @click="refresh(() => { })" src="@/static/icon/cactus.png" style="width: 3rem;height: 3rem;"></image>
          <br>
          <text>{{ $t('comments.null') }}</text>
        </view>
        <view v-else>
          <view v-for="item, i in data" :key="'comment' + i" class="comment">
            <view style="display: flex;">
              <view>
                <q-avatar class="avatar" :src="item.avatar" />
              </view>
              <view style="flex:1;padding: 0.25rem 0.5rem;">{{ item.user }}</view>
            </view>
            <view style="margin: 0.4rem 0;">{{ item.content }}</view>
            <view class="date" dir="auto">
              <text>
                <i><b>{{ $t('comments.posted') }}</b></i>{{ ' ' }}{{ formatDate(item.date) }}
              </text>
            </view>
          </view>
          <view style="text-align: center;padding-bottom: 1rem;padding: 0.5rem;">
            <text v-if="loading">
              <i class="fa-solid fa-circle-notch fa-spin" style="color: #00897b;margin-right: 0.4rem;"></i>
              <text>{{ $t('loading2') }}</text>
            </text>
            <text v-else>
              <text><i style="transform:scale(2.5,1)" class="fa-solid fa-minus"></i></text>
            </text>
          </view>
        </view>
      </view>
      <view class="addComment" dir="auto">
        <view style="flex:1">
          <input v-model="body" :placeholder="$t('comments.add')" class="addCommentInput" @focus="active = true"
            @blur="active = false" />
        </view>
        <view :style="{ width: active ? '4.5rem' : 0 }"
          style="width: 4.5rem;text-align: center;transition: width ease 100ms;overflow: hidden;white-space: nowrap;">
          <button size="mini" style="margin-top: 0.5rem" @click="addComment()">{{ $t('comments.submit')
          }}</button>
        </view>
      </view>
    </view>
  </view>
</template>
<script>
import { getImageInfoComments, addCommentForImage, formatDate } from '@/api/api.js'
export default {
  data() {
    return {
      onload: true,
      data: [],
      id: null,
      body: null,
      active: false,
      loading: false,
      page: 0,
    }
  },
  onPullDownRefresh() {
    this.refresh(() => {
      uni.stopPullDownRefresh()
    })
  },
  onReachBottom() {
    this.getComments(() => { })
  },
  onLoad: function (e) {
    console.log(e)
    this.id = e.id
  },
  onNavigationBarButtonTap(e) {
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  created() {
    uni.setNavigationBarTitle({
      title: this.$t('comments.title')
    })
    this.getComments(() => {
      this.onload = false
    })
  },
  methods: {
    refresh(cb) {
      this.onload = true
      this.data = []
      this.page = 0
      this.getComments(() => {
        this.onload = false
        cb()
      })
    },
    formatDate(t) {
      return formatDate(t)
    },
    getComments(cb) {
      this.loading = true
      getImageInfoComments(this.id, this.page, (res) => {
        this.loading = false
        for (let i = 0; i < res.results.length; i++) {
          this.data.push({
            user: res.results[i].user.name,
            content: res.results[i].body,
            date: res.results[i].createdAt,
            avatar: res.results[i].user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.results[i].user.avatar
              .id + '/' + res.results[i].user
                .avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg'
          })
        }
        this.page++
        cb()
      })
    },
    addComment() {
      addCommentForImage(this.id, this.body, (res, code) => {
        if (code == 201) {
          uni.showToast({
            title: this.$t('comments.success'),
            icon: "none",
            duration: 3000,
          })
          this.getComments()
        } else {
          uni.showToast({
            title: this.$t('comments.fail'),
            icon: "none",
            duration: 3000,
          })
        }
      })
    },
  }
}
</script>
<style>
.loading {
  width: 4rem;
  height: 4rem;
  animation: rotate 350ms linear infinite;
}

.comments {}

.avatar {
  width: 2rem;
  height: 2rem;
  box-shadow: 0 0 0.125rem #000a;
  border-radius: 2rem;
}

.comment {
  border-bottom: #aaaaaa 1px solid;
  padding: 1rem;
}

.addComment {
  display: flex;
  position: fixed;
  bottom: 0;
  width: 100%;
  background-color: #f5f5f5;
  box-shadow: 0 -0.25rem 0.25rem #0002;
}

.addCommentInput {
  margin: 0.5rem;
  padding: 0.5rem;
  border-bottom: solid 2px #00897b;
}

button {
  background-color: #00897b;
  color: #f0f0f0;
}

.date {
  text-align: right;
  color: #616161;
  font-size: 0.9rem;
}

@keyframes rotate {
  0% {
    transform: rotate(0deg);
  }

  25% {
    transform: rotate(90deg);
  }

  50% {
    transform: rotate(180deg);
  }

  75% {
    transform: rotate(270deg);
  }

  100% {
    transform: rotate(360deg);
  }
}

@media (prefers-color-scheme: dark) {
  .date {
    color: #BDBDBD
  }

  .comment {
    border-color: #616161;
  }

  .addComment {
    background-color: #101010;
    box-shadow: 0 -0.25rem 0.25rem #fff2;
  }
}
</style>