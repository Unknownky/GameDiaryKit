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
        :disabled="currentTime === 0 && currentPhase !== '准备开始'"
      >
        {{ isRunning ? '暂停' : (currentPhase === '准备开始' ? '开始' : '继续') }}
      </button>
      <button @click="resetTimer" class="btn-secondary">重置</button>
      <button @click="skipPhase" class="btn-secondary">跳过</button>
    </div>

    <div class="settings" v-if="!isRunning">
      <h3>设置</h3>
      <div class="setting-item">
        <label>工作时间 (分钟):</label>
        <input v-model.number="settings.workTime" type="number" min="1" max="60" />
      </div>
      <div class="setting-item">
        <label>短休息 (分钟):</label>
        <input v-model.number="settings.shortBreak" type="number" min="1" max="30" />
      </div>
      <div class="setting-item">
        <label>长休息 (分钟):</label>
        <input v-model.number="settings.longBreak" type="number" min="1" max="60" />
      </div>
      <div class="setting-item">
        <label>长休息周期:</label>
        <input v-model.number="settings.longBreakInterval" type="number" min="2" max="10" />
      </div>
      <div class="setting-item">
        <label>总结时间 (秒):</label>
        <input v-model.number="settings.summaryTime" type="number" min="30" max="300" />
      </div>
      <button @click="saveSettings" class="btn-save">保存设置</button>
    </div>

    <div class="stats">
      <div class="stat-item">
        <span class="label">今日完成:</span>
        <span class="value">{{ todayCompleted }} 个番茄</span>
      </div>
      <div class="stat-item">
        <span class="label">总计:</span>
        <span class="value">{{ totalCompleted }} 个番茄</span>
      </div>
    </div>

    <div class="help">
      <h4>快捷键</h4>
      <div class="shortcut-item">
        <span class="key">空格键</span>
        <span class="desc">开始/暂停</span>
      </div>
      <div class="shortcut-item">
        <span class="key">R</span>
        <span class="desc">重置</span>
      </div>
      <div class="shortcut-item">
        <span class="key">S</span>
        <span class="desc">跳过当前阶段</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'

// 响应式数据
const isRunning = ref(false)
const currentTime = ref(0)
const currentPhase = ref('准备开始')
const currentCycle = ref(1)
const completedPomodoros = ref(0)
const todayCompleted = ref(0)
const totalCompleted = ref(0)

// 设置
const settings = ref({
  workTime: 25,      // 工作时间（分钟）
  shortBreak: 5,     // 短休息（分钟）
  longBreak: 15,     // 长休息（分钟）
  longBreakInterval: 4, // 长休息周期
  summaryTime: 60    // 总结时间（秒）
})

// 计时器
let timer = null
let phaseStartTime = ref(0)

// 音效
const audioContext = ref(null)

// 阶段类型
const PHASES = {
  READY: '准备开始',
  WORK: '工作时间',
  SUMMARY: '总结时间',
  SHORT_BREAK: '短休息',
  LONG_BREAK: '长休息'
}

// 计算属性
const circumference = computed(() => 2 * Math.PI * 90)

const progress = computed(() => {
  if (phaseStartTime.value === 0) return 0
  return (phaseStartTime.value - currentTime.value) / phaseStartTime.value
})

const strokeDashoffset = computed(() => {
  return circumference.value * (1 - progress.value)
})

const phaseColor = computed(() => {
  switch (currentPhase.value) {
    case PHASES.WORK:
      return '#e74c3c'
    case PHASES.SUMMARY:
      return '#f39c12'
    case PHASES.SHORT_BREAK:
      return '#2ecc71'
    case PHASES.LONG_BREAK:
      return '#3498db'
    default:
      return '#95a5a6'
  }
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
    
    // 尝试使用Web Audio API
    if (typeof AudioContext !== 'undefined' || typeof webkitAudioContext !== 'undefined') {
      if (!audioContext.value) {
        audioContext.value = new (window.AudioContext || window.webkitAudioContext)()
      }
      
      const oscillator = audioContext.value.createOscillator()
      const gainNode = audioContext.value.createGain()
      
      oscillator.connect(gainNode)
      gainNode.connect(audioContext.value.destination)
      
      oscillator.frequency.setValueAtTime(800, audioContext.value.currentTime)
      gainNode.gain.setValueAtTime(0.3, audioContext.value.currentTime)
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.value.currentTime + 0.5)
      
      oscillator.start(audioContext.value.currentTime)
      oscillator.stop(audioContext.value.currentTime + 0.5)
    }
    
    // 显示uTools通知（如果在uTools环境中）
    if (window.utools && window.utools.showNotification) {
      const messages = {
        [PHASES.WORK]: '🍅 工作时间结束！开始总结。',
        [PHASES.SUMMARY]: '📝 总结时间结束！开始休息。',
        [PHASES.SHORT_BREAK]: '☕ 短休息结束！开始新的番茄钟。',
        [PHASES.LONG_BREAK]: '🎉 长休息结束！开始新的番茄钟。'
      }
      window.utools.showNotification(messages[currentPhase.value] || '⏰ 时间到！', 'pomodoro')
    }
  } catch (error) {
    console.log('音效播放失败:', error)
  }
}

const startNextPhase = () => {
  switch (currentPhase.value) {
    case PHASES.READY:
    case PHASES.SUMMARY:
      currentPhase.value = PHASES.WORK
      currentTime.value = settings.value.workTime * 60
      break
    case PHASES.WORK:
      completedPomodoros.value++
      todayCompleted.value++
      totalCompleted.value++
      saveStats()
      
      currentPhase.value = PHASES.SUMMARY
      currentTime.value = settings.value.summaryTime
      break
    case PHASES.SHORT_BREAK:
    case PHASES.LONG_BREAK:
      currentCycle.value++
      currentPhase.value = PHASES.WORK
      currentTime.value = settings.value.workTime * 60
      break
  }
  
  if (currentPhase.value === PHASES.SUMMARY) {
    // 总结时间是正计时
    phaseStartTime.value = settings.value.summaryTime
    currentTime.value = 0
  } else {
    phaseStartTime.value = currentTime.value
  }
}

const startBreakPhase = () => {
  const isLongBreak = completedPomodoros.value % settings.value.longBreakInterval === 0
  
  if (isLongBreak) {
    currentPhase.value = PHASES.LONG_BREAK
    currentTime.value = settings.value.longBreak * 60
  } else {
    currentPhase.value = PHASES.SHORT_BREAK
    currentTime.value = settings.value.shortBreak * 60
  }
  
  phaseStartTime.value = currentTime.value
}

const toggleTimer = () => {
  if (!isRunning.value) {
    if (currentPhase.value === PHASES.READY) {
      startNextPhase()
    }
    startTimer()
  } else {
    pauseTimer()
  }
}

const startTimer = () => {
  isRunning.value = true
  timer = setInterval(() => {
    if (currentPhase.value === PHASES.SUMMARY) {
      // 总结时间正计时
      currentTime.value++
      if (currentTime.value >= settings.value.summaryTime) {
        playNotificationSound()
        pauseTimer()
        startBreakPhase()
      }
    } else {
      // 其他阶段倒计时
      currentTime.value--
      if (currentTime.value <= 0) {
        playNotificationSound()
        pauseTimer()
        
        if (currentPhase.value === PHASES.WORK) {
          startNextPhase() // 进入总结时间
        } else {
          startNextPhase() // 进入下一个工作周期
        }
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
  currentPhase.value = PHASES.READY
  currentTime.value = 0
  phaseStartTime.value = 0
  currentCycle.value = 1
  completedPomodoros.value = 0
}

const skipPhase = () => {
  if (!isRunning.value) {
    if (currentPhase.value === PHASES.WORK) {
      startNextPhase() // 跳到总结时间
    } else if (currentPhase.value === PHASES.SUMMARY) {
      startBreakPhase() // 跳到休息时间
    } else {
      startNextPhase() // 跳到工作时间
    }
  }
}

const saveSettings = () => {
  try {
    // 优先使用uTools的数据库存储
    if (window.utools && window.utools.dbStorage) {
      window.utools.dbStorage.setItem('pomodoro-settings', JSON.stringify(settings.value))
    } else {
      localStorage.setItem('pomodoro-settings', JSON.stringify(settings.value))
    }
    
    if (window.utools && window.utools.showNotification) {
      window.utools.showNotification('⚙️ 设置已保存')
    } else {
      alert('设置已保存')
    }
  } catch (error) {
    console.error('保存设置失败:', error)
  }
}

const loadSettings = () => {
  try {
    let saved = null
    
    // 优先使用uTools的数据库
    if (window.utools && window.utools.dbStorage) {
      saved = window.utools.dbStorage.getItem('pomodoro-settings')
    } else {
      saved = localStorage.getItem('pomodoro-settings')
    }
    
    if (saved) {
      settings.value = { ...settings.value, ...JSON.parse(saved) }
    }
  } catch (error) {
    console.error('加载设置失败:', error)
  }
}

const saveStats = () => {
  try {
    const today = new Date().toDateString()
    const stats = {
      today,
      todayCompleted: todayCompleted.value,
      totalCompleted: totalCompleted.value
    }
    
    // 优先使用uTools的数据库存储
    if (window.utools && window.utools.dbStorage) {
      window.utools.dbStorage.setItem('pomodoro-stats', JSON.stringify(stats))
    } else {
      localStorage.setItem('pomodoro-stats', JSON.stringify(stats))
    }
  } catch (error) {
    console.error('保存统计失败:', error)
  }
}

const loadStats = () => {
  try {
    let saved = null
    
    // 优先使用uTools的数据库
    if (window.utools && window.utools.dbStorage) {
      saved = window.utools.dbStorage.getItem('pomodoro-stats')
    } else {
      saved = localStorage.getItem('pomodoro-stats')
    }
    
    if (saved) {
      const stats = JSON.parse(saved)
      const today = new Date().toDateString()
      
      totalCompleted.value = stats.totalCompleted || 0
      
      if (stats.today === today) {
        todayCompleted.value = stats.todayCompleted || 0
      } else {
        todayCompleted.value = 0
      }
    }
  } catch (error) {
    console.error('加载统计失败:', error)
  }
}

// 生命周期
onMounted(() => {
  loadSettings()
  loadStats()
  
  // 设置uTools窗口高度
  if (window.utools && window.utools.setExpendHeight) {
    window.utools.setExpendHeight(700)
  }
  
  // 添加键盘快捷键
  const handleKeyPress = (event) => {
    if (event.code === 'Space') {
      event.preventDefault()
      toggleTimer()
    } else if (event.code === 'KeyR') {
      event.preventDefault()
      resetTimer()
    } else if (event.code === 'KeyS') {
      event.preventDefault()
      skipPhase()
    }
  }
  
  document.addEventListener('keydown', handleKeyPress)
  
  // 清理函数
  onUnmounted(() => {
    document.removeEventListener('keydown', handleKeyPress)
  })
})

onUnmounted(() => {
  pauseTimer()
  if (audioContext.value) {
    audioContext.value.close()
  }
})

// 监听设置变化
watch(settings, () => {
  if (currentPhase.value === PHASES.READY) {
    currentTime.value = 0
  }
}, { deep: true })
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
.btn-secondary,
.btn-save {
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

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
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

.btn-save {
  background: linear-gradient(45deg, #4ecdc4, #44a08d);
  color: white;
  width: 100%;
  margin-top: 15px;
}

.btn-save:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(78, 205, 196, 0.3);
}

.settings {
  background: rgba(255, 255, 255, 0.1);
  padding: 20px;
  border-radius: 15px;
  margin: 30px 0;
  backdrop-filter: blur(10px);
}

.settings h3 {
  margin: 0 0 20px 0;
  text-align: center;
  font-size: 1.5em;
  font-weight: 300;
}

.setting-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.setting-item label {
  font-weight: 500;
}

.setting-item input {
  width: 80px;
  padding: 8px 12px;
  border: none;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  text-align: center;
  font-size: 1em;
}

.setting-item input::placeholder {
  color: rgba(255, 255, 255, 0.7);
}

.stats {
  background: rgba(255, 255, 255, 0.1);
  padding: 20px;
  border-radius: 15px;
  backdrop-filter: blur(10px);
  margin-bottom: 20px;
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

.help {
  background: rgba(255, 255, 255, 0.1);
  padding: 20px;
  border-radius: 15px;
  backdrop-filter: blur(10px);
}

.help h4 {
  margin: 0 0 15px 0;
  text-align: center;
  font-size: 1.2em;
  font-weight: 500;
}

.shortcut-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.shortcut-item:last-child {
  margin-bottom: 0;
}

.key {
  background: rgba(255, 255, 255, 0.2);
  padding: 4px 8px;
  border-radius: 6px;
  font-family: monospace;
  font-weight: 600;
  min-width: 40px;
  text-align: center;
}

.desc {
  opacity: 0.9;
}

/* 响应式设计 */
@media (max-width: 480px) {
  .pomodoro-container {
    padding: 15px;
  }
  
  .header h1 {
    font-size: 2em;
  }
  
  .time {
    font-size: 2.5em;
  }
  
  .controls {
    flex-direction: column;
    align-items: center;
  }
  
  .btn-primary,
  .btn-secondary {
    width: 100%;
    max-width: 200px;
  }
}
</style>
