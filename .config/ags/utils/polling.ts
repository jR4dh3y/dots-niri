import { createPoll } from "ags/time"

// Robust polling function that handles command failures gracefully
export function createRobustPoll(defaultValue: string, interval: number, command: string) {
  return createPoll(defaultValue, interval, `
    set -e
    trap 'echo "${defaultValue}"' ERR
    ${command}
  `)
}

// Safe async execution wrapper
export async function safeExecAsync(command: string): Promise<string> {
  try {
    const { execAsync } = await import("ags/process")
    return await execAsync(command)
  } catch (error) {
    console.error(`Command failed: ${command}`, error)
    return ""
  }
}
