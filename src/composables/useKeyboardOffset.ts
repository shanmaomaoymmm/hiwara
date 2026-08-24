import { ref, onMounted, onBeforeUnmount } from 'vue'

// 软键盘高度（移动端弹出键盘时，仅将底部输入组件抬升至键盘上方，页面其余内容保持不动）
//
// 原理：键盘弹出会压缩 visualViewport 的可视区高度，
// 差值 = window.innerHeight(layout 视口) - visualViewport.height 即为键盘遮挡高度。
//
// 必须配合原生 android:windowSoftInputMode="adjustNothing" 使用：
// - adjustNothing 保证系统在任何情况下都不平移/缩放窗口，页面其余部分（如视频）完全不动；
// - 本 composable 仅对输入组件自身做 translateY(-键盘高度)，输入框正好停留在键盘上方。
//
// 若原生是 adjustResize 且生效，layout 视口会被同步压缩（innerHeight 变小），
// 此时差值≈0，本逻辑自动不抬升，避免与原生行为叠加造成“位移一大块”。
// 桌面端无键盘时差值为 0，不做任何位移。
const KEYBOARD_THRESHOLD = 80 // 阈值：差值超过该值才视为键盘弹出，避免精度误差导致误位移

export function useKeyboardOffset() {
  const keyboardOffset = ref(0)

  function updateKeyboardOffset() {
    const vv = window.visualViewport
    if (!vv) {
      keyboardOffset.value = 0
      return
    }
    const diff = window.innerHeight - vv.height
    keyboardOffset.value = diff > KEYBOARD_THRESHOLD ? diff : 0
  }

  onMounted(() => {
    const vv = window.visualViewport
    if (vv) {
      vv.addEventListener('resize', updateKeyboardOffset)
      vv.addEventListener('scroll', updateKeyboardOffset)
    } else {
      window.addEventListener('resize', updateKeyboardOffset)
    }
    updateKeyboardOffset()
  })

  onBeforeUnmount(() => {
    const vv = window.visualViewport
    if (vv) {
      vv.removeEventListener('resize', updateKeyboardOffset)
      vv.removeEventListener('scroll', updateKeyboardOffset)
    } else {
      window.removeEventListener('resize', updateKeyboardOffset)
    }
  })

  return { keyboardOffset }
}
