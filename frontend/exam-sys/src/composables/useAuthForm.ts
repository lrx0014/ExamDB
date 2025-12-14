import { ref } from 'vue'

type Mode = 'register' | 'login'

const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8080'

export default function useAuthForm() {
  const mode = ref<Mode>('register')
  const email = ref('')
  const password = ref('')
  const fullName = ref('')
  const loading = ref(false)
  const error = ref('')
  const token = ref('')

  const submit = async () => {
    error.value = ''
    token.value = ''
    loading.value = true
    try {
      const path = mode.value === 'register' ? '/api/auth/register' : '/api/auth/login'
      const body =
        mode.value === 'register'
          ? { email: email.value, password: password.value, fullName: fullName.value }
          : { email: email.value, password: password.value }

      const res = await fetch(`${API_BASE}${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      })

      if (!res.ok) {
        const msg = (await res.json().catch(() => ({ message: 'Request failed' }))).message
        throw new Error(msg || 'Request failed')
      }
      const data = await res.json()
      token.value = data.token
    } catch (e: any) {
      error.value = e?.message || 'Something went wrong'
    } finally {
      loading.value = false
    }
  }

  return { mode, email, fullName, password, loading, error, token, submit }
}
