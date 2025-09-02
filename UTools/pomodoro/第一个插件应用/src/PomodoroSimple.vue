<template>
  <div class="pomodoro-container">
    <div class="header">
      <h1>🍅 番茄钟</h1>
      <div class="status">
        <span class="phase">{{ currentPhase }}</span>
        <span class="cycle">第 {{ currentCycle }} 个番茄</span>
      </div>
    </div>

    <div class="timer-display">
      <div class="time">{{ formatTime(currentTime) }}</div>
      <div class="progress-ring">
        <svg width="200" height="200">
          <circle
            cx="100"
            cy="100"
            r="90"
            fill="none"
            stroke="#e6e6e6"
            stroke-width="10"
          />
          <circle
            cx="100"
            cy="100"
            r="90"
            fill="none"
            :stroke="phaseColor"
            stroke-width="10"
            :stroke-dasharray="circumference"
            :stroke-dashoffset="strokeDashoffset"
            transform="rotate(-90 100 100)"
            class="progress-circle"
          />
        </svg>
      </div>
    </div>

    <div class="controls">
      <button 
        @click="toggleTimer" 
        class="btn-primary"
      >
        {{ isRunning ? '暂停' : '开始' }}
      </button>
      <button @click="resetTimer" class="btn-secondary">重置</button>
    </div>

    <div class="stats">
      <div class="stat-item">
        <span class="label">今日完成:</span>
        <span class="value">{{ todayCompleted }} 个番茄</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

// 响应式数据
const isRunning = ref(false)
const currentTime = ref(1500) // 25分钟 = 1500秒
const currentPhase = ref('工作时间')
const currentCycle = ref(1)
const todayCompleted = ref(0)

// 计时器
let timer = null
const totalTime = ref(1500)

// 阶段类型
const PHASES = {
  WORK: '工作时间',
  BREAK: '休息时间'
}

// 计算属性
const circumference = computed(() => 2 * Math.PI * 90)

const progress = computed(() => {
  if (totalTime.value === 0) return 0
  return (totalTime.value - currentTime.value) / totalTime.value
})

const strokeDashoffset = computed(() => {
  return circumference.value * (1 - progress.value)
})

const phaseColor = computed(() => {
  return currentPhase.value === PHASES.WORK ? '#e74c3c' : '#2ecc71'
})

// 方法
const formatTime = (seconds) => {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

const playNotificationSound = () => {
  try {
    // 播放系统提示音
    if (window.utools && window.utools.shellBeep) {
      window.utools.shellBeep()
    }
    
    // 显示通知
    if (window.utools && window.utools.showNotification) {
      const message = currentPhase.value === PHASES.WORK ? 
        '🍅 工作时间结束！' : '☕ 休息时间结束！'
      window.utools.showNotification(message)
    }
  } catch (error) {
    console.log('通知失败:', error)
  }
}

const toggleTimer = () => {
  if (!isRunning.value) {
    startTimer()
  } else {
    pauseTimer()
  }
}

const startTimer = () => {
  isRunning.value = true
  timer = setInterval(() => {
    currentTime.value--
    if (currentTime.value <= 0) {
      playNotificationSound()
      pauseTimer()
      
      if (currentPhase.value === PHASES.WORK) {
        // 工作完成，进入休息
        todayCompleted.value++
        currentPhase.value = PHASES.BREAK
        currentTime.value = 300 // 5分钟休息
        totalTime.value = 300
      } else {
        // 休息完成，进入工作
        currentCycle.value++
        currentPhase.value = PHASES.WORK
        currentTime.value = 1500 // 25分钟工作
        totalTime.value = 1500
      }
    }
  }, 1000)
}

const pauseTimer = () => {
  isRunning.value = false
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}

const resetTimer = () => {
  pauseTimer()
  currentPhase.value = PHASES.WORK
  currentTime.value = 1500
  totalTime.value = 1500
  currentCycle.value = 1
}

// 生命周期
onMounted(() => {
  // 设置uTools窗口高度
  if (window.utools && window.utools.setExpendHeight) {
    window.utools.setExpendHeight(600)
  }
  
  // 设置uTools回调
  if (window.utools) {
    window.utools.onPluginEnter((action) => {
      console.log('插件激活:', action)
    })
    
    window.utools.onPluginOut((isKill) => {
      pauseTimer()
    })
  }
})

onUnmounted(() => {
  pauseTimer()
})
</script>

<style scoped>
.pomodoro-container {
  max-width: 500px;
  margin: 0 auto;
  padding: 20px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  color: white;
}

.header {
  text-align: center;
  margin-bottom: 30px;
}

.header h1 {
  margin: 0 0 10px 0;
  font-size: 2.5em;
  font-weight: 300;
}

.status {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: rgba(255, 255, 255, 0.1);
  padding: 10px 20px;
  border-radius: 25px;
  backdrop-filter: blur(10px);
}

.phase {
  font-size: 1.2em;
  font-weight: 600;
}

.cycle {
  font-size: 1em;
  opacity: 0.8;
}

.timer-display {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 40px 0;
}

.time {
  position: absolute;
  font-size: 3em;
  font-weight: 300;
  z-index: 2;
}

.progress-ring {
  position: relative;
}

.progress-circle {
  transition: stroke-dashoffset 1s ease;
}

.controls {
  display: flex;
  justify-content: center;
  gap: 15px;
  margin: 30px 0;
}

.btn-primary,
.btn-secondary {
  padding: 12px 24px;
  border: none;
  border-radius: 25px;
  font-size: 1em;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary {
  background: linear-gradient(45deg, #ff6b6b, #ee5a52);
  color: white;
  box-shadow: 0 4px 15px rgba(255, 107, 107, 0.3);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(255, 107, 107, 0.4);
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  backdrop-filter: blur(10px);
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.stats {
  background: rgba(255, 255, 255, 0.1);
  padding: 20px;
  border-radius: 15px;
  backdrop-filter: blur(10px);
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.stat-item:last-child {
  margin-bottom: 0;
}

.label {
  font-weight: 500;
}

.value {
  font-weight: 600;
  font-size: 1.1em;
}
</style>
