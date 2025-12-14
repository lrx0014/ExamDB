<script setup lang="ts">
import useAuthForm from '../composables/useAuthForm'

const {
  mode,
  email,
  fullName,
  password,
  loading,
  error,
  token,
  submit,
} = useAuthForm()
</script>

<template>
  <div class="card">
    <div class="tabs">
      <button :class="{ active: mode === 'register' }" @click="mode = 'register'">Register</button>
      <button :class="{ active: mode === 'login' }" @click="mode = 'login'">Login</button>
    </div>

    <form @submit.prevent="submit">
      <label class="field">
        <span>Email</span>
        <input v-model="email" type="email" required />
      </label>

      <label v-if="mode === 'register'" class="field">
        <span>Full name</span>
        <input v-model="fullName" type="text" required />
      </label>

      <label class="field">
        <span>Password</span>
        <input v-model="password" type="password" required />
      </label>

      <p class="error" v-if="error">{{ error }}</p>
      <p class="token" v-if="token">JWT: {{ token }}</p>

      <button class="primary" type="submit" :disabled="loading">
        {{ loading ? 'Working...' : mode === 'register' ? 'Create account' : 'Login' }}
      </button>
    </form>
  </div>
</template>
