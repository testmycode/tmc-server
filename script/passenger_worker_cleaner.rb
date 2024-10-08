#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'

# Configuration Constants
PASSENGER_STATUS_CMD = 'passenger-status'
MIN_WORKERS_ALLOWED = 4
LAST_USED_THRESHOLD_SECONDS = 10 * 60  # 10 minutes

# Class representing a single Passenger Worker Process
class WorkerProcess
  attr_reader :pid, :sessions, :processed, :uptime_seconds, :cpu, :memory_mb, :last_used_seconds

  def initialize(pid:, sessions:, processed:, uptime_str:, cpu:, memory_str:, last_used_str:)
    @pid = pid
    @sessions = sessions
    @processed = processed
    @uptime_seconds = parse_time(uptime_str)
    @cpu = cpu
    @memory_mb = parse_memory(memory_str)
    @last_used_seconds = parse_time(last_used_str)
  end

  # Parses a time string like "16m 52s" into total seconds
  def parse_time(time_str)
    total_seconds = 0
    # Match patterns like "16m", "52s", etc.
    time_str.scan(/(\d+)m|(\d+)s/) do |min, sec|
      total_seconds += min.to_i * 60 if min
      total_seconds += sec.to_i if sec
    end
    total_seconds
  end

  # Parses memory string like "184M", "1.2G", "512K" into integer megabytes
  def parse_memory(mem_str)
    match = mem_str.strip.match(/^([\d.]+)\s*([KMGTP])?$/i)
    return 0 unless match

    value = match[1].to_f
    unit = match[2]&.upcase || 'M'

    case unit
    when 'K'
      (value / 1024).round(2)
    when 'M'
      value.round(2)
    when 'G'
      (value * 1024).round(2)
    when 'T'
      (value * 1024 * 1024).round(2)
    when 'P'
      (value * 1024 * 1024 * 1024).round(2)
    else
      value.round(2)
    end
  end

  def to_s
    "PID: #{@pid}, Last Used: #{@last_used_seconds}s, Memory: #{@memory_mb} MB"
  end
end

# Class responsible for executing and parsing passenger-status output
class PassengerStatusParser
  attr_reader :total_processes, :workers

  def initialize(command: PASSENGER_STATUS_CMD)
    @command = command
    @total_processes = 0
    @workers = []
  end

  def execute
    stdout, stderr, status = Open3.capture3(@command)

    unless status.success?
      raise "Error executing #{@command}: #{stderr}"
    end

    parse(stdout)
  end

  private
    def parse(output)
      current_worker_data = {}
      in_app_group = false

      output.each_line do |line|
        line = line.strip

        # Capture total processes using regex to handle variable whitespace
        if line =~ /^Processes\s*:\s*(\d+)/
          @total_processes = Regexp.last_match(1).to_i
          next
        end

        # Detect start of Application groups
        if line =~ /^-+ Application groups -+$/
          in_app_group = true
          next
        end

        next unless in_app_group

        # Start of a worker entry using regex to handle variable whitespace
        if line =~ /^\*\s*PID\s*:\s*(\d+)\s+Sessions\s*:\s*(\d+)\s+Processed\s*:\s*(\d+)\s+Uptime\s*:\s*([\dm\s]+s)/
          # Save previous worker if exists
          if current_worker_data.any?
            @workers << build_worker(current_worker_data)
            current_worker_data = {}
          end

          # Extract PID, Sessions, Processed, Uptime
          current_worker_data[:pid] = Regexp.last_match(1).to_i
          current_worker_data[:sessions] = Regexp.last_match(2).to_i
          current_worker_data[:processed] = Regexp.last_match(3).to_i
          current_worker_data[:uptime_str] = Regexp.last_match(4).strip
          next
        end

        # Extract CPU and Memory using regex to handle variable whitespace
        if line =~ /^CPU\s*:\s*([\d.]+)%\s+Memory\s*:\s*([\d.]+\s*[KMGTP]?)/i
          current_worker_data[:cpu] = Regexp.last_match(1).to_f
          current_worker_data[:memory_str] = Regexp.last_match(2).strip
          next
        end

        # Extract Last used using regex to handle variable whitespace
        if line =~ /^Last\s+used\s*:\s*([\dm\s]+s)\s*(?:ago|ag)?/i
          current_worker_data[:last_used_str] = Regexp.last_match(1).strip
          next
        end
      end

      # Add the last worker if exists
      if current_worker_data.any?
        @workers << build_worker(current_worker_data)
      end
    end

    def build_worker(data)
      WorkerProcess.new(
        pid: data[:pid],
        sessions: data[:sessions],
        processed: data[:processed],
        uptime_str: data[:uptime_str],
        cpu: data[:cpu],
        memory_str: data[:memory_str],
        last_used_str: data[:last_used_str]
      )
    end
end

# Class responsible for managing Passenger Workers
class PassengerWorkerManager
  def initialize(parser: PassengerStatusParser.new)
    @parser = parser
  end

  def run
    begin
      @parser.execute
    rescue => e
      puts e.message
      exit 1
    end

    total_processes = @parser.total_processes
    workers = @parser.workers

    puts "Total Processes: #{total_processes}"
    puts "Total Workers: #{workers.size}"

    if total_processes > MIN_WORKERS_ALLOWED
      puts "Number of processes (#{total_processes}) exceeds the minimum allowed (#{MIN_WORKERS_ALLOWED})."

      worker_to_kill = find_worker_to_kill(workers)

      if worker_to_kill
        pid = worker_to_kill.pid
        last_used_seconds = worker_to_kill.last_used_seconds
        last_used_minutes = (last_used_seconds / 60).to_i
        last_used_seconds_remainder = last_used_seconds % 60

        puts "Killing worker PID #{pid} with last used time of #{last_used_minutes}m #{last_used_seconds_remainder}s and memory: #{worker_to_kill.memory_mb} MB."

        kill_worker(pid)
      else
        puts "No workers have been idle for more than #{LAST_USED_THRESHOLD_SECONDS / 60} minutes."
      end
    else
      puts "Number of processes (#{total_processes}) is under (#{MIN_WORKERS_ALLOWED}). No action needed."
    end
  end

  private
    def find_worker_to_kill(workers)
      eligible_workers = workers.select { |w| w.last_used_seconds > LAST_USED_THRESHOLD_SECONDS }

      return nil if eligible_workers.empty?

      # Find the worker with the maximum last used time
      eligible_workers.max_by { |w| w.last_used_seconds }
    end

    def kill_worker(pid)
      Process.kill('TERM', pid)
      puts "Successfully sent TERM signal to PID #{pid}."
    rescue Errno::ESRCH
      puts "Process with PID #{pid} does not exist."
    rescue Errno::EPERM
      puts "Insufficient permissions to kill PID #{pid}."
    rescue => e
      puts "Failed to kill PID #{pid}: #{e.message}"
    end
end

manager = PassengerWorkerManager.new
manager.run
